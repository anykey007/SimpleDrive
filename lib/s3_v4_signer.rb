require "openssl"
require "digest"
require "time"

class S3V4Signer
  attr_reader :access_key_id, :secret_access_key, :region

  def initialize(access_key_id:, secret_access_key:, region: "us-east-1")
    @access_key_id = access_key_id
    @secret_access_key = secret_access_key
    @region = region || "us-east-1"
  end

  def sign(method:, canonical_uri:, headers:, hashed_payload:, time: Time.now.utc)
    amz_date = time.strftime("%Y%m%dT%H%M%SZ")
    date_stamp = time.strftime("%Y%m%d")

    headers = headers.dup
    headers["X-Amz-Date"] = amz_date
    headers["X-Amz-Content-Sha256"] = hashed_payload

    processed_headers = {}
    headers.each do |k, v|
      processed_headers[k.downcase.strip] = v.strip.gsub(/\s+/, " ")
    end

    sorted_header_keys = processed_headers.keys.sort
    canonical_headers = sorted_header_keys.map { |k| "#{k}:#{processed_headers[k]}" }.join("\n") + "\n"
    signed_headers = sorted_header_keys.join(";")

    canonical_query = ""

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
    headers
  end

  def uri_encode(string)
    string.b.gsub(/([^a-zA-Z0-9_.\-~]+)/) do |match|
      "%" + match.unpack("H2" * match.bytesize).join("%").upcase
    end
  end

  private

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
