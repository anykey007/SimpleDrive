require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid with tenant and email" do
    assert users(:jim).valid?
  end

  test "invalid without an email" do
    user = User.new(tenant: tenants(:acme))

    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test "invalid with duplicate email in the same tenant" do
    user = User.new(tenant: tenants(:acme), email: users(:jim).email)

    assert_not user.valid?
    assert_includes user.errors[:email], "has already been taken"
  end

  test "valid with duplicate email in another tenant" do
    user = User.new(tenant: tenants(:globex), email: users(:jim).email)

    assert user.valid?
  end

  test "has many api tokens" do
    assert_includes users(:jim).api_tokens, api_tokens(:jim_token)
  end
end
