require "test_helper"
require "base64"

module BlobsRequests
  module S3
    class StoreBlobTest < ActionDispatch::IntegrationTest
      test "successfully saves blob record and stores file in S3" do
        assert_difference -> { Blob.count }, 1 do
          post "/v1/blobs",
            params: valid_params,
            headers: auth_header(users(:bob)),
            as: :json
        end

        assert_response :no_content

        blob = Blob.last
        assert_equal valid_params[:id], blob.external_id
        assert_equal users(:bob), blob.user

        expected_provider = storage_providers(:globex_s3)
        assert_equal expected_provider, blob.storage_provider
        assert_equal "s3", expected_provider.adapter_type

        # Verify we can retrieve the stored content from the real S3 bucket
        adapter = Storage::Factory.build(expected_provider, storage_key: blob.storage_key)
        retrieved = adapter.retrieve
        assert_equal "Hello Simple Storage World!", retrieved.read
      ensure
        retrieved&.close if retrieved.respond_to?(:close)
      end
    end
  end
end
