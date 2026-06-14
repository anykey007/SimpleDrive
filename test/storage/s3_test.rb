require "test_helper"
require "stringio"

class Storage::S3Test < ActiveSupport::TestCase
  setup do
    @bucket = "test-s3-bucket"
    @storage_key = "test_file_key"
  end

  test "stores file content to s3" do
    config = storage_providers(:two).configuration

    storage = Storage::S3.new(
      bucket: config["bucket"],
      access_key_id: config["access_key_id"],
      secret_access_key: config["secret_access_key"],
      endpoint: config["endpoint"],
      region: config["region"],
      force_path_style: config["force_path_style"],
      storage_key: @storage_key
    )

    io = StringIO.new("Hello S3 World!")

    # Verify bucket check and put_object are executed without error
    result = storage.store(io: io)
    assert_equal @storage_key, result

    # Retrieves stored file content from s3
    retrieved = storage.retrieve
    assert_equal "Hello S3 World!", retrieved.read
  ensure
    retrieved&.close
  end
end
