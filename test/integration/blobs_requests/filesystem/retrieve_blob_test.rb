require "test_helper"
require "fileutils"

module BlobsRequests
  module Filesystem
    class RetrieveBlobTest < ActionDispatch::IntegrationTest
      test "GET /v1/blobs/:id retrieves blob from filesystem successfully" do
        post "/v1/blobs",
          params: valid_params,
          headers: auth_header("jim_token"),
          as: :json

        get "/v1/blobs/#{valid_params[:id]}",
          headers: auth_header("jim_token")

        assert_response :success
        assert_json_response(response, valid_params)
      end

      test "GET /v1/blobs/:id retrieves blob with slashes and special characters in id successfully" do
        special_id = "documents/2026/archive(final)+draft-v2_approved?\\image.pdf"
        special_params = {
          id: special_id,
          data: Base64.strict_encode64("Hello Slashes and Special Chars!")
        }

        post "/v1/blobs",
          params: special_params,
          headers: auth_header("jim_token"),
          as: :json

        assert_response :created

        # In URL, ? is %3F, \ is %5C
        get "/v1/blobs/documents/2026/archive(final)+draft-v2_approved%3F%5Cimage.pdf",
          headers: auth_header("jim_token")

        assert_response :success
        assert_json_response(response, special_params)
      end

      test "GET /v1/blobs/:id returns 404 with custom error if blob exists but storage file is missing" do
        # This blob has no real file stored in filesystem
        get "/v1/blobs/#{blobs(:readme_blob).external_id}",
          headers: auth_header("jim_token")

        assert_response :not_found
        json_response = JSON.parse(response.body)
        assert_includes json_response["error"], "File content is missing on storage server"
      end

      test "GET /v1/blobs/:id returns 404 if blob exists but status is pending" do
        blob = blobs(:readme_blob)
        blob.update!(status: :pending)

        get "/v1/blobs/#{blob.external_id}",
          headers: auth_header("jim_token")

        assert_response :not_found
        json_response = JSON.parse(response.body)
        assert_equal "Blob not found", json_response["error"]
      end

      test "GET /v1/blobs/:id returns 404 if blob exists but status is failed" do
        blob = blobs(:readme_blob)
        blob.update!(status: :failed)

        get "/v1/blobs/#{blob.external_id}",
          headers: auth_header("jim_token")

        assert_response :not_found
        json_response = JSON.parse(response.body)
        assert_equal "Blob not found", json_response["error"]
      end
    end
  end
end
