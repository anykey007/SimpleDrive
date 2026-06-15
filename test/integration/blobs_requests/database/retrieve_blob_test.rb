require "test_helper"

module BlobsRequests
  module Database
    class RetrieveBlobTest < ActionDispatch::IntegrationTest
      test "GET /v1/blobs/:id retrieves blob from database successfully using fixture" do
        blob = blobs(:cyberdyne_blob)

        get "/v1/blobs/#{blob.external_id}", headers: auth_header(users(:sarah))

        assert_response :success
        json_response = JSON.parse(response.body)
        assert_equal blob.external_id, json_response["id"]
        assert_equal Base64.strict_encode64("Hello Database Storage World!"), json_response["data"]
        assert_equal "29", json_response["size"]
      end
    end
  end
end
