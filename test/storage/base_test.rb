require "test_helper"

class Storage::BaseTest < ActiveSupport::TestCase
  test "store must be implemented by subclasses" do
    error = assert_raises(NotImplementedError) { Storage::Base.new.store }

    assert_equal "Storage::Base must implement #store", error.message
  end

  test "retrieve must be implemented by subclasses" do
    error = assert_raises(NotImplementedError) { Storage::Base.new.retrieve }

    assert_equal "Storage::Base must implement #retrieve", error.message
  end
end
