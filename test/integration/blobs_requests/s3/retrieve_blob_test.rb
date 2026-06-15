require "test_helper"
require "base64"

module BlobsRequests
  module S3
    class RetrieveBlobTest < ActionDispatch::IntegrationTest
      test "GET /v1/blobs/:id retrieves blob from S3 successfully" do
        post "/v1/blobs",
          params: valid_params,
          headers: auth_header(users(:bob)),
          as: :json
        assert_response :no_content

        get "/v1/blobs/#{valid_params[:id]}",
          headers: auth_header(users(:bob))

        assert_response :success
        json_response = JSON.parse(response.body)
        assert_equal valid_params[:id], json_response["id"]
        assert_equal valid_params[:data], json_response["data"]
        assert_equal "27", json_response["size"]
        assert_match(/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/, json_response["created_at"])
      end
    end
  end
end
