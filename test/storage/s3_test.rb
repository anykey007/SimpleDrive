require "test_helper"
require "stringio"

class Storage::S3Test < ActiveSupport::TestCase
  setup do
    @bucket = "test-s3-bucket"
    @storage_key = "test_file_key"
  end

  test "raises ArgumentError when storage_key is missing" do
    assert_raises(ArgumentError) { Storage::S3.new(storage_key: nil) }
  end

  test "raises Storage::ConfigurationError when required options are missing" do
    error = assert_raises(Storage::ConfigurationError) do
      Storage::S3.new(storage_key: @storage_key)
    end
    assert_equal ["access_key_id", "bucket", "endpoint", "secret_access_key"], error.missing_keys
  end

  test "stores file content to s3" do
    config = storage_providers(:two).configuration

    storage = Storage::S3.new(
      options: config,
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

  test "raises Storage::FileNotFoundError when retrieving non-existent file from S3" do
    config = storage_providers(:two).configuration

    storage = Storage::S3.new(
      options: config,
      storage_key: "non_existent_s3_key_12345"
    )

    assert_raises(Storage::FileNotFoundError) do
      storage.retrieve
    end
  end
end
