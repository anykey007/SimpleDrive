require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid with tenant and email" do
    assert users(:one).valid?
  end

  test "invalid without an email" do
    user = User.new(tenant: tenants(:one))

    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test "invalid with duplicate email in the same tenant" do
    user = User.new(tenant: tenants(:one), email: users(:one).email)

    assert_not user.valid?
    assert_includes user.errors[:email], "has already been taken"
  end

  test "valid with duplicate email in another tenant" do
    user = User.new(tenant: tenants(:two), email: users(:one).email)

    assert user.valid?
  end

  test "has many api tokens" do
    assert_includes users(:one).api_tokens, api_tokens(:one)
  end
end
