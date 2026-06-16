require "net/http"
require "openssl"
require "digest"
require "uri"
require "time"
require "cgi"
require_relative "s3_v4_signer"

class S3Client
  attr_reader :bucket, :endpoint, :signer

  def initialize(bucket:, access_key_id:, secret_access_key:, endpoint:, region: "us-east-1")
    @bucket = bucket
    @endpoint = endpoint
    @signer = S3V4Signer.new(
      access_key_id: access_key_id,
      secret_access_key: secret_access_key,
      region: region
    )
  end

  def put_object(key, body)
    request_url, canonical_uri, host = build_request_url_and_canonical_uri(key)
    payload_str = extract_payload_string(body)

    signed_headers = signer.sign(
      method: "PUT",
      canonical_uri: canonical_uri,
      headers: headers = { "Host" => host },
      hashed_payload: Digest::SHA256.hexdigest(payload_str)
    )

    req = Net::HTTP::Put.new(request_url.request_uri)
    signed_headers.each { |k, v| req[k] = v }
    req.body = payload_str
    req["Content-Length"] = payload_str.bytesize.to_s

    send_request_and_verify(request_url, req)
  end

  def get_object(key)
    request_url, canonical_uri, host = build_request_url_and_canonical_uri(key)

    signed_headers = signer.sign(
      method: "GET",
      canonical_uri: canonical_uri,
      headers: { "Host" => host },
      hashed_payload: Digest::SHA256.hexdigest("")
    )

    req = Net::HTTP::Get.new(request_url.request_uri)
    signed_headers.each { |k, v| req[k] = v }

    send_request_and_verify(request_url, req)
  end

  private

  def build_request_url_and_canonical_uri(key)
    uri = URI(@endpoint)
    path_prefix = uri.path.chomp("/")

    canonical_uri = "#{path_prefix}/#{@bucket}/#{key}"
    host = uri.host
    host += ":#{uri.port}" if uri.port && !([ 80, 443 ].include?(uri.port) && [ "http", "https" ].include?(uri.scheme))
    url_str = "#{uri.scheme}://#{host}#{canonical_uri}"

    [ URI(url_str), canonical_uri, host ]
  end

  def extract_payload_string(body)
    payload = body || ""
    if payload.respond_to?(:read)
      payload.rewind if payload.respond_to?(:rewind)
      content = payload.read
      payload.rewind if payload.respond_to?(:rewind)
      content
    else
      payload.to_s
    end
  end

  def create_http_client(request_url)
    http = Net::HTTP.new(request_url.host, request_url.port)
    if request_url.scheme == "https"
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    end
    http.open_timeout = 5
    http.read_timeout = 10
    http
  end

  def send_request_and_verify(request_url, req)
    http = create_http_client(request_url)
    response = http.request(req)
    unless response.code.to_i >= 200 && response.code.to_i < 300
      raise "S3 request failed with code #{response.code}: #{response.body}"
    end
    response
  end
end
