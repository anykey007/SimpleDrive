require "test_helper"
require "fileutils"

module BlobsRequests
  class BaseTest < ActionDispatch::IntegrationTest
  test "returns unprocessable entity when no active storage provider exists" do
    storage_providers(:acme_filesystem).update(active: false)

    assert_no_difference -> { Blob.count } do
      post "/v1/blobs",
        params: valid_params,
        headers: auth_header("jim_token"),
        as: :json
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "No active storage provider found"
  end

  test "returns unprocessable entity when blob validation fails" do
    Blob.create!(
      user: users(:jim),
      storage_provider: storage_providers(:acme_filesystem),
      external_id: valid_params[:id],
      size_bytes: 10,
      checksum_sha256: "dummy_checksum",
      storage_key: "existing_key"
    )

    assert_no_difference -> { Blob.count } do
      post "/v1/blobs",
        params: valid_params,
        headers: auth_header("jim_token"),
        as: :json
    end

    assert_response :unprocessable_entity
    assert_includes JSON.parse(response.body)["errors"].to_s, "External has already been taken"
  end

  test "rejects request without bearer token" do
    post "/v1/blobs",
      params: valid_params,
      as: :json

    assert_response :unauthorized
  end

  test "rejects request with invalid bearer token" do
    post "/v1/blobs",
      params: valid_params,
      headers: { "Authorization" => "Bearer invalid-token" },
      as: :json

    assert_response :unauthorized
  end

  test "rejects request with invalid base64 data" do
    post "/v1/blobs",
      params: { id: "any_valid_string_or_identifier", data: "not valid base64" },
      headers: auth_header("jim_token"),
      as: :json

    assert_response :unprocessable_entity
  end

  test "GET /v1/blobs/:id returns 404 if blob not found" do
    get "/v1/blobs/non_existent_id",
      headers: auth_header("jim_token")

    assert_response :not_found
    json_response = JSON.parse(response.body)
    assert_equal "Blob not found", json_response["error"]
  end


  test "GET /v1/blobs/:id returns 401 if unauthorized" do
    get "/v1/blobs/some_id"
    assert_response :unauthorized

    get "/v1/blobs/some_id",
      headers: { "Authorization" => "Bearer invalid-token" }
    assert_response :unauthorized
  end

  test "GET /v1/blobs/:id does not allow a user to access other user's blobs" do
    get "/v1/blobs/#{blobs(:cyberdyne_blob).external_id}",
      headers: auth_header("jim_token")

    assert_response :not_found
  end

  test "POST /v1/blobs returns 413 Payload Too Large when request exceeds the limit" do
    ENV["MAX_REQUEST_SIZE_BYTES"] = "20"
    begin
      post "/v1/blobs",
        params: valid_params,
        headers: auth_header("jim_token"),
        as: :json

      assert_response 413
      json_response = JSON.parse(response.body)
      assert_equal "Payload Too Large", json_response["error"]
      assert_equal 20, json_response["max_allowed_bytes"]
    ensure
      ENV.delete("MAX_REQUEST_SIZE_BYTES")
    end
  end
  end
end
