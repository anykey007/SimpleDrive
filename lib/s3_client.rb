require "net/http"
require "openssl"
require "digest"
require "uri"
require "time"
require "cgi"

class S3Client
  attr_reader :bucket, :access_key_id, :secret_access_key, :endpoint, :region, :force_path_style

  def initialize(bucket:, access_key_id:, secret_access_key:, endpoint:, region: "us-east-1", force_path_style: true)
    @bucket = bucket
    @access_key_id = access_key_id
    @secret_access_key = secret_access_key
    @endpoint = endpoint
    @region = region || "us-east-1"
    @force_path_style = force_path_style.nil? ? true : force_path_style
  end

  def uri_encode(string)
    string.b.gsub(/([^a-zA-Z0-9_.\-~]+)/) do |match|
      "%" + match.unpack("H2" * match.bytesize).join("%").upcase
    end
  end

  def put_object(key, body)
    request("PUT", key, body)
  end

  def get_object(key)
    request("GET", key)
  end

  private

  def request(method, key, body = nil)
    uri = URI(@endpoint)
    path_prefix = uri.path.chomp('/')

    if @force_path_style
      canonical_uri = "#{path_prefix}/#{@bucket}/#{key}"
      host = uri.host
      host += ":#{uri.port}" if uri.port && !([80, 443].include?(uri.port) && ["http", "https"].include?(uri.scheme))
      url_str = "#{uri.scheme}://#{host}#{canonical_uri}"
    else
      canonical_uri = "#{path_prefix}/#{key}"
      host = "#{@bucket}.#{uri.host}"
      host += ":#{uri.port}" if uri.port && !([80, 443].include?(uri.port) && ["http", "https"].include?(uri.scheme))
      url_str = "#{uri.scheme}://#{host}#{canonical_uri}"
    end

    request_url = URI(url_str)

    payload = body || ""
    payload_str = if payload.respond_to?(:read)
                    payload.rewind if payload.respond_to?(:rewind)
                    content = payload.read
                    payload.rewind if payload.respond_to?(:rewind)
                    content
                  else
                    payload.to_s
                  end

    hashed_payload = Digest::SHA256.hexdigest(payload_str)

    now = Time.now.utc
    amz_date = now.strftime("%Y%m%dT%H%M%SZ")
    date_stamp = now.strftime("%Y%m%d")

    headers = {
      "Host" => host,
      "X-Amz-Content-Sha256" => hashed_payload,
      "X-Amz-Date" => amz_date
    }

    canonical_query = ""

    # Sort and format headers for canonical representation
    processed_headers = {}
    headers.each do |k, v|
      processed_headers[k.downcase.strip] = v.strip.gsub(/\s+/, " ")
    end

    sorted_header_keys = processed_headers.keys.sort
    canonical_headers = sorted_header_keys.map { |k| "#{k}:#{processed_headers[k]}" }.join("\n") + "\n"
    signed_headers = sorted_header_keys.join(";")

    encoded_uri_parts = canonical_uri.split("/").map { |segment| uri_encode(segment) }
    canonical_uri_encoded = encoded_uri_parts.join("/")
    canonical_uri_encoded = "/" if canonical_uri_encoded.empty?
    canonical_uri_encoded += "/" if canonical_uri.end_with?("/") && !canonical_uri_encoded.end_with?("/")

    canonical_request = [
      method,
      canonical_uri_encoded,
      canonical_query,
      canonical_headers,
      signed_headers,
      hashed_payload
    ].join("\n")

    credential_scope = "#{date_stamp}/#{@region}/s3/aws4_request"
    string_to_sign = [
      "AWS4-HMAC-SHA256",
      amz_date,
      credential_scope,
      Digest::SHA256.hexdigest(canonical_request)
    ].join("\n")

    signing_key = get_signature_key(@secret_access_key, date_stamp, @region, "s3")
    signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"), signing_key, string_to_sign)

    authorization_header = "AWS4-HMAC-SHA256 Credential=#{@access_key_id}/#{credential_scope}, SignedHeaders=#{signed_headers}, Signature=#{signature}"
    headers["Authorization"] = authorization_header

    http = Net::HTTP.new(request_url.host, request_url.port)
    if request_url.scheme == "https"
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    http.open_timeout = 5
    http.read_timeout = 10

    case method
    when "PUT"
      req = Net::HTTP::Put.new(request_url.request_uri)
      headers.each { |k, v| req[k] = v }
      req.body = payload_str
      req["Content-Length"] = payload_str.bytesize.to_s
    when "GET"
      req = Net::HTTP::Get.new(request_url.request_uri)
      headers.each { |k, v| req[k] = v }
    else
      raise ArgumentError, "Unsupported HTTP method: #{method}"
    end

    response = http.request(req)

    unless response.code.to_i >= 200 && response.code.to_i < 300
      raise "S3 request failed with code #{response.code}: #{response.body}"
    end

    response
  end

  def get_signature_key(key, date_stamp, region_name, service_name)
    k_date    = hmac_sha256("AWS4" + key, date_stamp)
    k_region  = hmac_sha256(k_date, region_name)
    k_service = hmac_sha256(k_region, service_name)
    k_signing = hmac_sha256(k_service, "aws4_request")
    k_signing
  end

  def hmac_sha256(key, data)
    OpenSSL::HMAC.digest(OpenSSL::Digest.new("sha256"), key, data)
  end
end
