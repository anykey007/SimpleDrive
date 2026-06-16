require "test_helper"
require "base64"

module BlobsRequests
  module S3
    class RetrieveBlobTest < ActionDispatch::IntegrationTest
      test "GET /v1/blobs/:id retrieves blob from S3 successfully" do
        post "/v1/blobs",
          params: valid_params,
          headers: auth_header("bob_token"),
          as: :json
        assert_response :created
        assert_json_response(response, valid_params, check_data: false)

        get "/v1/blobs/#{valid_params[:id]}",
          headers: auth_header("bob_token")

        assert_response :success
        assert_json_response(response, valid_params)
      end
    end
  end
end
