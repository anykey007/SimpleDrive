require "test_helper"

class Storage::BaseTest < ActiveSupport::TestCase
  test "raises ArgumentError when storage_key is missing or nil" do
    assert_raises(ArgumentError) { Storage::Base.new }
    assert_raises(ArgumentError) { Storage::Base.new(storage_key: nil) }
  end

  test "initializes options with indifferent access" do
    base = Storage::Base.new(storage_key: "some_key", options: { "foo" => "bar" })
    assert_equal "bar", base.options[:foo]
    assert_equal "bar", base.options["foo"]
    assert_instance_of ActiveSupport::HashWithIndifferentAccess, base.options
  end

  test "options defaults to empty hash" do
    base = Storage::Base.new(storage_key: "some_key")
    assert_empty base.options
    assert_instance_of ActiveSupport::HashWithIndifferentAccess, base.options
  end

  test "store must be implemented by subclasses" do
    error = assert_raises(NotImplementedError) { Storage::Base.new(storage_key: "some_key").store }

    assert_equal "Storage::Base must implement #store", error.message
  end

  test "retrieve must be implemented by subclasses" do
    error = assert_raises(NotImplementedError) { Storage::Base.new(storage_key: "some_key").retrieve }

    assert_equal "Storage::Base must implement #retrieve", error.message
  end

  test "require_options! raises Storage::ConfigurationError with sorted missing options" do
    base = Storage::Base.new(storage_key: "some_key", options: { "foo" => "bar" })

    assert_nothing_raised do
      base.send(:require_options!, :foo)
    end

    error = assert_raises(Storage::ConfigurationError) do
      base.send(:require_options!, :foo, :baz, :qux)
    end

    assert_equal [ "baz", "qux" ], error.missing_keys
    assert_equal "Storage::Base", error.adapter_class
    assert_equal "Missing required options: baz, qux for Storage::Base", error.message
  end

  test "required_options registers the keys and validates them on initialize" do
    # Create a dummy subclass with required_options
    dummy_class = Class.new(Storage::Base) do
      required_options :foo, :bar
    end

    # Missing all required options
    error = assert_raises(Storage::ConfigurationError) do
      dummy_class.new(storage_key: "some_key")
    end
    assert_equal ["bar", "foo"], error.missing_keys

    # Missing some required options
    error2 = assert_raises(Storage::ConfigurationError) do
      dummy_class.new(storage_key: "some_key", options: { foo: "present" })
    end
    assert_equal ["bar"], error2.missing_keys

    # All required options present
    assert_nothing_raised do
      dummy_class.new(storage_key: "some_key", options: { foo: "present", bar: "present" })
    end
  end

  test "Storage register and adapter_class_for dynamic registration" do
    dummy_class = Class.new(Storage::Base)
    Storage.register(:dummy, dummy_class)

    assert_equal dummy_class, Storage.adapter_class_for(:dummy)
    assert_equal dummy_class, Storage.adapter_class_for("dummy")

    assert_raises(ArgumentError) do
      Storage.adapter_class_for(:non_existent)
    end
  end
end
