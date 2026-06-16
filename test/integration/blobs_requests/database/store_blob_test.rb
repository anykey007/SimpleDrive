require "test_helper"

module BlobsRequests
  module Database
    class StoreBlobTest < ActionDispatch::IntegrationTest
      test "successfully saves blob record and stores file in the database" do
        assert_difference -> { Blob.count }, 1 do
          post "/v1/blobs",
            params: valid_params,
            headers: auth_header(users(:sarah)),
            as: :json
        end

        assert_response :created
        assert_json_response(response, valid_params, check_data: false)

        blob = Blob.last
        assert_equal valid_params[:id], blob.external_id
        assert_equal users(:sarah), blob.user
        assert_equal storage_providers(:cyberdyne_database), blob.storage_provider

        db_object = BlobDataObject.find_by(storage_key: blob.storage_key)
        assert_not_nil db_object
        assert_equal "Hello Simple Storage World!", db_object.data
      end
    end
  end
end
