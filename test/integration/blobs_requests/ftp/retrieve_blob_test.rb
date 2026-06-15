require "test_helper"
require "base64"
require "stringio"

module BlobsRequests
  module Ftp
    class RetrieveBlobTest < ActionDispatch::IntegrationTest
      setup do
        @blob = blobs(:uplink_blob)
        storage_provider = @blob.storage_provider
        adapter = Storage::Factory.build(storage_provider, storage_key: @blob.storage_key)
        adapter.store(io: StringIO.new("Hello FTP World!"))
      end

      test "GET /v1/blobs/:id retrieves blob from FTP successfully using fixture" do
        get "/v1/blobs/#{@blob.external_id}",
          headers: auth_header(users(:uplink_user))

        assert_response :success
        json_response = JSON.parse(response.body)
        assert_equal @blob.external_id, json_response["id"]
        assert_equal Base64.strict_encode64("Hello FTP World!"), json_response["data"]
        assert_equal "16", json_response["size"]
      end
    end
  end
end
