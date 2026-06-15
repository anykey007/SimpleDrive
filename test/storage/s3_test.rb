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
end
