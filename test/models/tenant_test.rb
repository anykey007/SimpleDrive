require "test_helper"

class TenantTest < ActiveSupport::TestCase
  test "valid with a name" do
    assert tenants(:one).valid?
  end

  test "invalid without a name" do
    tenant = Tenant.new

    assert_not tenant.valid?
    assert_includes tenant.errors[:name], "can't be blank"
  end

  test "has many users" do
    assert_includes tenants(:one).users, users(:one)
  end
end
