require "test_helper"

class ApiTokenTest < ActiveSupport::TestCase
  test "valid with user and token digest" do
    assert api_tokens(:one).valid?
  end

  test "invalid without a token digest" do
    api_token = ApiToken.new(user: users(:one))

    assert_not api_token.valid?
    assert_includes api_token.errors[:token_digest], "can't be blank"
  end

  test "invalid with duplicate token digest" do
    api_token = ApiToken.new(user: users(:one), token_digest: api_tokens(:one).token_digest)

    assert_not api_token.valid?
    assert_includes api_token.errors[:token_digest], "has already been taken"
  end
end
