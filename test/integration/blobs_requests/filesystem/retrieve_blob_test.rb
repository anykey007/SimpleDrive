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
        json_response = JSON.parse(response.body)
        assert_equal valid_params[:id], json_response["id"]
        assert_equal valid_params[:data], json_response["data"]
        assert_equal "27", json_response["size"]
        assert_match(/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/, json_response["created_at"])
      end

      test "GET /v1/blobs/:id returns 404 with custom error if blob exists but storage file is missing" do
        # This blob has no real file stored in filesystem
        get "/v1/blobs/#{blobs(:readme_blob).external_id}",
          headers: auth_header(users(:jim))

        assert_response :not_found
        json_response = JSON.parse(response.body)
        assert_includes json_response["error"], "File content is missing on storage server"
      end
    end
  end
end
