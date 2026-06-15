require "test_helper"

class StorageProviderTest < ActiveSupport::TestCase
  test "valid with tenant, name, adapter type and configuration" do
    assert storage_providers(:acme_filesystem).valid?
  end

  test "invalid without a tenant" do
    storage_provider = StorageProvider.new(name: "Primary", adapter_type: "local", configuration: {})

    assert_not storage_provider.valid?
    assert_includes storage_provider.errors[:tenant], "must exist"
  end

  test "invalid without a name" do
    storage_provider = StorageProvider.new(tenant: tenants(:acme), adapter_type: "local", configuration: {})

    assert_not storage_provider.valid?
    assert_includes storage_provider.errors[:name], "can't be blank"
  end

  test "invalid without an adapter type" do
    storage_provider = StorageProvider.new(tenant: tenants(:acme), name: "Secondary", configuration: {})

    assert_not storage_provider.valid?
    assert_includes storage_provider.errors[:adapter_type], "can't be blank"
  end

  test "invalid with duplicate name in the same tenant" do
    storage_provider = StorageProvider.new(
      tenant: tenants(:acme),
      name: storage_providers(:acme_filesystem).name,
      adapter_type: "local",
      configuration: {}
    )

    assert_not storage_provider.valid?
    assert_includes storage_provider.errors[:name], "has already been taken"
  end

  test "valid with duplicate name in another tenant" do
    storage_provider = StorageProvider.new(
      tenant: tenants(:globex),
      name: storage_providers(:acme_filesystem).name,
      adapter_type: "local",
      configuration: {}
    )

    assert storage_provider.valid?
  end

  test "uses default configuration and active values" do
    storage_provider = StorageProvider.create!(tenant: tenants(:acme), name: "Archive", adapter_type: "local")

    assert_equal({}, storage_provider.configuration)
    assert_equal true, storage_provider.active
  end
end
