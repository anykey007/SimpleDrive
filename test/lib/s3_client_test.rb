require "test_helper"
require "stringio"

class S3ClientTest < ActiveSupport::TestCase
  setup do
    @client = S3Client.new(
      bucket: "test-s3-bucket",
      access_key_id: "minio",
      secret_access_key: "minio123456",
      endpoint: "http://localhost:9000",
      region: "us-east-1"
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
end
