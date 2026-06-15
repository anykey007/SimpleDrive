require "test_helper"
require "fileutils"

module BlobsRequests
  module Filesystem
    class StoreBlobTest < ActionDispatch::IntegrationTest
      test "successfully saves blob record and stores file in the filesystem" do
        SecureRandom.stub(:uuid, ->() { "abcdef" }) do
          assert_difference -> { Blob.count }, 1 do
            post "/v1/blobs",
              params: valid_params,
              headers: auth_header(users(:jim)),
              as: :json
          end

          assert_response :no_content

          blob = Blob.last
          assert_equal valid_params[:id], blob.external_id
          assert_equal users(:jim), blob.user

          expected_provider = storage_providers(:acme_filesystem)
          assert_equal expected_provider, blob.storage_provider

          expected_file_path = "tmp/test_storage/acme/ab/cd/abcdef"

          assert_path_exists expected_file_path
          assert_equal "Hello Simple Storage World!", File.binread(expected_file_path)
        end
      end

      test "POST /v1/blobs returns 422 if storing the file fails with Storage::WriteDataError" do
        storage_provider = storage_providers(:acme_filesystem)
        mock_adapter = Storage::Filesystem.new(options: storage_provider.configuration, storage_key: "dummy_key")

        mock_adapter.stub(:store, ->(*args) { raise Storage::WriteDataError.new("dummy_key", "Simulated write failure") }) do
          Storage::Factory.stub(:build, mock_adapter) do
            assert_no_difference -> { Blob.count } do
              post "/v1/blobs",
                params: valid_params,
                headers: auth_header(users(:jim)),
                as: :json
            end

            assert_response :unprocessable_entity
            json_response = JSON.parse(response.body)
            assert_includes json_response["error"], "Failed to store file"
            assert_includes json_response["error"], "Simulated write failure"
          end
        end
      end
    end
  end
end
