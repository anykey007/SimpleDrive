require "test_helper"
require "base64"

module BlobsRequests
  module Ftp
    class StoreBlobTest < ActionDispatch::IntegrationTest
      test "successfully saves blob record and stores file in the FTP server" do
        provider = storage_providers(:uplink_ftp)

        assert_difference -> { Blob.count }, 1 do
          post "/v1/blobs",
            params: valid_params,
            headers: auth_header(users(:uplink_user)),
            as: :json
        end

        assert_response :no_content

        blob = Blob.last
        assert_equal valid_params[:id], blob.external_id
        assert_equal users(:uplink_user), blob.user
        assert_equal provider, blob.storage_provider

        # Verify that the file actually exists and has the correct content on FTP
        adapter = Storage::Factory.build(provider, storage_key: blob.storage_key)
        retrieved = adapter.retrieve
        assert_equal "Hello Simple Storage World!", retrieved.read
      ensure
        retrieved&.close if retrieved.respond_to?(:close)
      end
    end
  end
end
