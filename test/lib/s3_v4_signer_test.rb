require "test_helper"

class S3V4SignerTest < ActiveSupport::TestCase
  setup do
    @signer = S3V4Signer.new(
      access_key_id: "test_access_key",
      secret_access_key: "test_secret_key",
      region: "us-east-1"
    )
  end

  test "uri_encode formats correctly according to RFC 3986" do
    assert_equal "hello%20world", @signer.uri_encode("hello world")
    assert_equal "a-b_c.d~e", @signer.uri_encode("a-b_c.d~e")
    assert_equal "%2Fpath%2Fto%2Ffile", @signer.uri_encode("/path/to/file")
  end

  test "sign returns hash containing authorization, date, and payload hash headers" do
    method = "GET"
    canonical_uri = "/test-bucket/test-key"
    headers = { "Host" => "localhost:9000" }
    hashed_payload = Digest::SHA256.hexdigest("")
    time = Time.utc(2026, 6, 16, 12, 0, 0)

    signed_headers = @signer.sign(
      method: method,
      canonical_uri: canonical_uri,
      headers: headers,
      hashed_payload: hashed_payload,
      time: time
    )

    assert_equal "20260616T120000Z", signed_headers["X-Amz-Date"]
    assert_equal hashed_payload, signed_headers["X-Amz-Content-Sha256"]
    assert_match(/\AAWS4-HMAC-SHA256 Credential=test_access_key\/20260616\/us-east-1\/s3\/aws4_request, SignedHeaders=host;x-amz-content-sha256;x-amz-date, Signature=[a-f0-9]{64}\z/, signed_headers["Authorization"])
  end
end
