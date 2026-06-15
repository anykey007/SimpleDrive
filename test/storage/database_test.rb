require "test_helper"
require "stringio"

class Storage::DatabaseTest < ActiveSupport::TestCase
  setup do
    # Clear the blob_data_objects table before each test to ensure isolation
    BlobDataObject.delete_all
  end

  test "stores text file content in database successfully" do
    storage_key = "test-database-key-1"
    storage = Storage::Database.new(storage_key: storage_key)
    io = StringIO.new("Hello Database Storage World!")

    returned_key = storage.store(io: io)

    assert_equal storage_key, returned_key

    db_object = BlobDataObject.find_by(storage_key: storage_key)
    assert_not_nil db_object
    assert_equal "Hello Database Storage World!", db_object.data
  end

  test "stores binary content successfully" do
    storage_key = "test-database-key-binary"
    storage = Storage::Database.new(storage_key: storage_key)
    binary_data = "\x00\xFF\xAA\xBBhello".b
    io = StringIO.new(binary_data)

    storage.store(io: io)

    db_object = BlobDataObject.find_by(storage_key: storage_key)
    assert_equal binary_data, db_object.data.force_encoding("ASCII-8BIT")
  end

  test "retrieves stored database blob as readable io" do
    storage_key = "test-database-key-retrieve"
    storage = Storage::Database.new(storage_key: storage_key)
    storage.store(io: StringIO.new("retrieved content"))

    retrieved = storage.retrieve

    assert_instance_of StringIO, retrieved
    assert_equal "retrieved content", retrieved.read
  end

  test "raises ArgumentError when storage_key is missing" do
    assert_raises(ArgumentError) do
      Storage::Database.new(storage_key: nil)
    end

    assert_raises(ArgumentError) do
      Storage::Database.new
    end
  end

  test "raises ActiveRecord::RecordNotFound when key is not found on retrieve" do
    storage = Storage::Database.new(storage_key: "non-existent-key")

    assert_raises(ActiveRecord::RecordNotFound) do
      storage.retrieve
    end
  end
end
