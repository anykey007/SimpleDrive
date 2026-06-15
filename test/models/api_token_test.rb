require "test_helper"

class ApiTokenTest < ActiveSupport::TestCase
  test "valid with user and token digest" do
    assert api_tokens(:jim_token).valid?
  end

  test "invalid without a token digest" do
    api_token = ApiToken.new(user: users(:jim))

    assert_not api_token.valid?
    assert_includes api_token.errors[:token_digest], "can't be blank"
  end

  test "invalid with duplicate token digest" do
    api_token = ApiToken.new(user: users(:jim), token_digest: api_tokens(:jim_token).token_digest)

    assert_not api_token.valid?
    assert_includes api_token.errors[:token_digest], "has already been taken"
  end
end
