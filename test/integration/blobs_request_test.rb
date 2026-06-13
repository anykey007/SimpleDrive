require "test_helper"
require "base64"

class BlobsRequestTest < ActionDispatch::IntegrationTest
  setup do
    @valid_params = {
      id: "any_valid_string_or_identifier",
      data: Base64.strict_encode64("Hello Simple Storage World!")
    }
  end

  test "accepts request with valid bearer token and base64 data" do
    post "/v1/blobs",
      params: @valid_params,
      headers: auth_headers,
      as: :json

    assert_response :no_content
  end

  test "rejects request without bearer token" do
    post "/v1/blobs",
      params: @valid_params,
      as: :json

    assert_response :unauthorized
  end

  test "rejects request with invalid bearer token" do
    post "/v1/blobs",
      params: @valid_params,
      headers: { "Authorization" => "Bearer invalid-token" },
      as: :json

    assert_response :unauthorized
  end

  test "rejects request with invalid base64 data" do
    post "/v1/blobs",
      params: { id: "any_valid_string_or_identifier", data: "not valid base64" },
      headers: auth_headers,
      as: :json

    assert_response :unprocessable_entity
  end

  private

  def auth_headers
    { "Authorization" => "Bearer 6d4769052b644be4c3f96ee67faa4bbb8ab8aa8be46055f2cea1e513cec22d52" }
  end
end
