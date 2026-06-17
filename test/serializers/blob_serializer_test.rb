require "test_helper"

class BlobSerializerTest < ActiveSupport::TestCase
  setup do
    @blob = blobs(:readme_blob)
  end

  test "BlobSerializer serializes only id, size, and created_at" do
    serializer = BlobSerializer.new(@blob)
    json = serializer.as_json

    assert_equal @blob.external_id, json[:id]
    assert_equal @blob.size_bytes.to_s, json[:size]
    assert_equal @blob.created_at.utc.iso8601, json[:created_at]
    assert_nil json[:data], "BlobSerializer should not contain the data attribute"
    assert_equal 3, json.keys.size, "BlobSerializer should only have 3 attributes"
  end

  test "BlobShowSerializer serializes id, size, created_at, and base64 encoded data" do
    raw_data = "Hello World"
    serializer = BlobShowSerializer.new(@blob, raw_data)
    json = serializer.as_json

    assert_equal @blob.external_id, json[:id]
    assert_equal @blob.size_bytes.to_s, json[:size]
    assert_equal @blob.created_at.utc.iso8601, json[:created_at]
    assert_equal Base64.strict_encode64(raw_data), json[:data]
    assert_equal 4, json.keys.size, "BlobShowSerializer should have exactly 4 attributes"
  end
end
