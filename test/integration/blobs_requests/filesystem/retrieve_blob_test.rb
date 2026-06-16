require "test_helper"
require "fileutils"

module BlobsRequests
  module Filesystem
    class RetrieveBlobTest < ActionDispatch::IntegrationTest
      test "GET /v1/blobs/:id retrieves blob from filesystem successfully" do
        post "/v1/blobs",
          params: valid_params,
          headers: auth_header(users(:jim)),
          as: :json

        get "/v1/blobs/#{valid_params[:id]}",
          headers: auth_header(users(:jim))

        assert_response :success
        assert_json_response(response, valid_params)
      end

      test "GET /v1/blobs/:id returns 404 with custom error if blob exists but storage file is missing" do
        # This blob has no real file stored in filesystem
        get "/v1/blobs/#{blobs(:readme_blob).external_id}",
          headers: auth_header(users(:jim))

        assert_response :not_found
        json_response = JSON.parse(response.body)
        assert_includes json_response["error"], "File content is missing on storage server"
      end

      test "GET /v1/blobs/:id returns 404 if blob exists but status is pending" do
        blob = blobs(:readme_blob)
        blob.update!(status: :pending)

        get "/v1/blobs/#{blob.external_id}",
          headers: auth_header(users(:jim))

        assert_response :not_found
        json_response = JSON.parse(response.body)
        assert_equal "Blob not found", json_response["error"]
      end

      test "GET /v1/blobs/:id returns 404 if blob exists but status is failed" do
        blob = blobs(:readme_blob)
        blob.update!(status: :failed)

        get "/v1/blobs/#{blob.external_id}",
          headers: auth_header(users(:jim))

        assert_response :not_found
        json_response = JSON.parse(response.body)
        assert_equal "Blob not found", json_response["error"]
      end
    end
  end
end
