require "test_helper"
require "base64"
require "fileutils"

class BlobsRequestTest < ActionDispatch::IntegrationTest
  setup do
    @valid_params = {
      id: "any_valid_string_or_identifier",
      data: Base64.strict_encode64("Hello Simple Storage World!")
    }
  end

  teardown do
    FileUtils.rm_rf(Rails.root.join("test_storage/one"))
  end

  test "accepts request with valid bearer token and base64 data" do
    post "/v1/blobs",
      params: @valid_params,
      headers: auth_headers,
      as: :json

    assert_response :no_content
  end

  test "successfully saves blob record and stores file in the filesystem" do
    assert_difference -> { Blob.count }, 1 do
      post "/v1/blobs",
        params: @valid_params,
        headers: auth_headers,
        as: :json
    end

    assert_response :no_content

    blob = Blob.last
    assert_equal @valid_params[:id], blob.external_id
    assert_equal users(:one), blob.user

    expected_provider = api_tokens(:one).user.tenant.storage_providers.active.first
    assert_equal expected_provider, blob.storage_provider

    expected_file_path = Rails.root.join(
      expected_provider.configuration["storage_path"],
      blob.storage_key[0, 2],
      blob.storage_key[2, 2],
      blob.storage_key
    )

    assert_path_exists expected_file_path
    assert_equal "Hello Simple Storage World!", File.binread(expected_file_path)
  end

  test "returns unprocessable entity when no active storage provider exists" do
    api_tokens(:one).user.tenant.storage_providers.update_all(active: false)

    assert_no_difference -> { Blob.count } do
      post "/v1/blobs",
        params: @valid_params,
        headers: auth_headers,
        as: :json
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "No active storage provider found"
  end

  test "returns unprocessable entity when blob validation fails" do
    Blob.create!(
      user: users(:one),
      storage_provider: storage_providers(:one),
      external_id: @valid_params[:id],
      size_bytes: 10,
      checksum_sha256: "dummy_checksum",
      storage_key: "existing_key"
    )

    assert_no_difference -> { Blob.count } do
      post "/v1/blobs",
        params: @valid_params,
        headers: auth_headers,
        as: :json
    end

    assert_response :unprocessable_entity
    assert_includes JSON.parse(response.body)["errors"].to_s, "External has already been taken"
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
