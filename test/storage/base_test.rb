require "test_helper"

class Storage::BaseTest < ActiveSupport::TestCase
  test "raises ArgumentError when storage_key is missing or nil" do
    assert_raises(ArgumentError) { Storage::Base.new }
    assert_raises(ArgumentError) { Storage::Base.new(storage_key: nil) }
  end

  test "store must be implemented by subclasses" do
    error = assert_raises(NotImplementedError) { Storage::Base.new(storage_key: "some_key").store }

    assert_equal "Storage::Base must implement #store", error.message
  end

  test "retrieve must be implemented by subclasses" do
    error = assert_raises(NotImplementedError) { Storage::Base.new(storage_key: "some_key").retrieve }

    assert_equal "Storage::Base must implement #retrieve", error.message
  end
end
