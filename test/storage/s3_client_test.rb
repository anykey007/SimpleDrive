require "test_helper"
require "stringio"

class S3ClientTest < ActiveSupport::TestCase
  setup do
    config = storage_providers(:globex_s3).configuration
    @client = S3Client.new(
      bucket: config["bucket"],
      access_key_id: config["access_key_id"],
      secret_access_key: config["secret_access_key"],
      endpoint: config["endpoint"],
      region: config["region"],
      force_path_style: config["force_path_style"]
    )
    @key = "s3_client_test_key"
  end

  test "put_object and get_object on real s3 compatible endpoint" do
    data = "Direct client Hello S3 World!"
    
    # Test PUT
    put_response = @client.put_object(@key, data)
    assert_equal "200", put_response.code

    # Test GET
    get_response = @client.get_object(@key)
    assert_equal "200", get_response.code
    assert_equal data, get_response.body
  end

  test "uri_encode formats correctly according to RFC 3986" do
    assert_equal "hello%20world", @client.uri_encode("hello world")
    assert_equal "a-b_c.d~e", @client.uri_encode("a-b_c.d~e")
    assert_equal "%2Fpath%2Fto%2Ffile", @client.uri_encode("/path/to/file")
  end
end
