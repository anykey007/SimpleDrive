require "test_helper"
require "base64"
require "fileutils"

class BlobsRequestTest < ActionDispatch::IntegrationTest
  setup do
    @created_files = []
    @valid_params = {
      id: "any_valid_string_or_identifier",
      data: Base64.strict_encode64("Hello Simple Storage World!")
    }
    BlobDataObject.delete_all
  end

  teardown do
    @created_files.each { |path| FileUtils.rm_f(path) }
  end

  test "accepts request with valid bearer token and base64 data" do
    post "/v1/blobs",
      params: @valid_params,
      headers: auth_headers,
      as: :json

    assert_response :no_content
    track_created_blob_file
  end

  test "successfully saves blob record and stores file in the filesystem" do
    assert_difference -> { Blob.count }, 1 do
      post "/v1/blobs",
        params: @valid_params,
        headers: auth_headers,
        as: :json
    end

    assert_response :no_content

    blob = Blob.last
    assert_equal @valid_params[:id], blob.external_id
    assert_equal users(:jim), blob.user

    expected_provider = storage_providers(:acme_filesystem)
    assert_equal expected_provider, blob.storage_provider

    expected_file_path = Rails.root.join(
      expected_provider.configuration["storage_path"],
      blob.storage_key[0, 2],
      blob.storage_key[2, 2],
      blob.storage_key
    )

    @created_files << expected_file_path

    assert_path_exists expected_file_path
    assert_equal "Hello Simple Storage World!", File.binread(expected_file_path)
  end

  test "successfully saves blob record and stores file in S3" do
    assert_difference -> { Blob.count }, 1 do
      post "/v1/blobs",
        params: @valid_params,
        headers: { "Authorization" => "Bearer 93367a826d78632eb54957f467e10fa0628213e2c1896fb0c37338f7fb9f4c26" },
        as: :json
    end

    assert_response :no_content

    blob = Blob.last
    assert_equal @valid_params[:id], blob.external_id
    assert_equal users(:bob), blob.user

    expected_provider = storage_providers(:globex_s3)
    assert_equal expected_provider, blob.storage_provider
    assert_equal "s3", expected_provider.adapter_type

    # Verify we can retrieve the stored content from the real S3 bucket
    adapter = Storage::Factory.build(expected_provider, storage_key: blob.storage_key)
    retrieved = adapter.retrieve
    assert_equal "Hello Simple Storage World!", retrieved.read
  ensure
    retrieved&.close
  end

  test "successfully saves blob record and stores file in the database" do
    provider = storage_providers(:cyberdyne_database)
    db_headers = { "Authorization" => "Bearer d88214fa3ca59d332d78632eb54957f467e10fa0628213e2c1896fb0c37338ff" }

    assert_difference -> { Blob.count }, 1 do
      post "/v1/blobs",
        params: @valid_params,
        headers: db_headers,
        as: :json
    end

    assert_response :no_content

    blob = Blob.last
    assert_equal @valid_params[:id], blob.external_id
    assert_equal users(:sarah), blob.user
    assert_equal provider, blob.storage_provider

    # Verify that the blob content is stored in the database's blob_data_objects table
    db_object = BlobDataObject.find_by(storage_key: blob.storage_key)
    assert_not_nil db_object
    assert_equal "Hello Simple Storage World!", db_object.data

    # Now verify GET /v1/blobs/:id retrieves the database blob successfully
    get "/v1/blobs/#{@valid_params[:id]}",
      headers: db_headers

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal @valid_params[:id], json_response["id"]
    assert_equal @valid_params[:data], json_response["data"]
    assert_equal "27", json_response["size"]
  end

  test "returns unprocessable entity when no active storage provider exists" do
    api_tokens(:jim_token).user.tenant.storage_providers.update_all(active: false)

    assert_no_difference -> { Blob.count } do
      post "/v1/blobs",
        params: @valid_params,
        headers: auth_headers,
        as: :json
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "No active storage provider found"
  end

  test "returns unprocessable entity when blob validation fails" do
    Blob.create!(
      user: users(:jim),
      storage_provider: storage_providers(:acme_filesystem),
      external_id: @valid_params[:id],
      size_bytes: 10,
      checksum_sha256: "dummy_checksum",
      storage_key: "existing_key"
    )

    assert_no_difference -> { Blob.count } do
      post "/v1/blobs",
        params: @valid_params,
        headers: auth_headers,
        as: :json
    end

    assert_response :unprocessable_entity
    assert_includes JSON.parse(response.body)["errors"].to_s, "External has already been taken"
  end

  test "rejects request without bearer token" do
    post "/v1/blobs",
      params: @valid_params,
      as: :json

    assert_response :unauthorized
  end

  test "rejects request with invalid bearer token" do
    post "/v1/blobs",
      params: @valid_params,
      headers: { "Authorization" => "Bearer invalid-token" },
      as: :json

    assert_response :unauthorized
  end

  test "rejects request with invalid base64 data" do
    post "/v1/blobs",
      params: { id: "any_valid_string_or_identifier", data: "not valid base64" },
      headers: auth_headers,
      as: :json

    assert_response :unprocessable_entity
  end

  test "GET /v1/blobs/:id retrieves blob from filesystem successfully" do
    post "/v1/blobs",
      params: @valid_params,
      headers: auth_headers,
      as: :json
    assert_response :no_content
    track_created_blob_file

    get "/v1/blobs/#{@valid_params[:id]}",
      headers: auth_headers

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal @valid_params[:id], json_response["id"]
    assert_equal @valid_params[:data], json_response["data"]
    assert_equal "27", json_response["size"]
    assert_match(/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/, json_response["created_at"])
  end

  test "GET /v1/blobs/:id retrieves blob from S3 successfully" do
    post "/v1/blobs",
      params: @valid_params,
      headers: { "Authorization" => "Bearer 93367a826d78632eb54957f467e10fa0628213e2c1896fb0c37338f7fb9f4c26" },
      as: :json
    assert_response :no_content

    get "/v1/blobs/#{@valid_params[:id]}",
      headers: { "Authorization" => "Bearer 93367a826d78632eb54957f467e10fa0628213e2c1896fb0c37338f7fb9f4c26" }

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal @valid_params[:id], json_response["id"]
    assert_equal @valid_params[:data], json_response["data"]
    assert_equal "27", json_response["size"]
    assert_match(/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/, json_response["created_at"])
  end

  test "GET /v1/blobs/:id with a path containing slashes retrieves blob successfully" do
    path_id = "/dir1/dir2/CV.pdf"
    params = {
      id: path_id,
      data: Base64.strict_encode64("Hello Simple Storage World!")
    }

    post "/v1/blobs",
      params: params,
      headers: auth_headers,
      as: :json
    assert_response :no_content
    track_created_blob_file

    get "/v1/blobs/dir1/dir2/CV.pdf",
      headers: auth_headers

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal path_id, json_response["id"]
    assert_equal params[:data], json_response["data"]
    assert_equal "27", json_response["size"]

    get "/v1/blobs//dir1/dir2/CV.pdf",
      headers: auth_headers
    assert_response :success
  end

  test "GET /v1/blobs/:id returns 404 if blob not found" do
    get "/v1/blobs/non_existent_id",
      headers: auth_headers

    assert_response :not_found
    json_response = JSON.parse(response.body)
    assert_equal "Blob not found", json_response["error"]
  end

  test "GET /v1/blobs/:id returns 404 with custom error if blob exists but storage file is missing" do
    # Create a blob record
    post "/v1/blobs",
      params: @valid_params,
      headers: auth_headers,
      as: :json
    assert_response :no_content

    # Locate the file on disk and delete it
    blob = Blob.find_by!(external_id: @valid_params[:id])
    provider = blob.storage_provider
    file_path = Rails.root.join(
      provider.configuration["storage_path"],
      blob.storage_key[0, 2],
      blob.storage_key[2, 2],
      blob.storage_key
    )
    assert_path_exists file_path
    FileUtils.rm(file_path)

    # Now retrieve the blob, it should return 404 Not Found instead of 500
    get "/v1/blobs/#{@valid_params[:id]}",
      headers: auth_headers

    assert_response :not_found
    json_response = JSON.parse(response.body)
    assert_includes json_response["error"], "File content is missing on storage server"
  end

  test "GET /v1/blobs/:id returns 401 if unauthorized" do
    get "/v1/blobs/some_id"
    assert_response :unauthorized

    get "/v1/blobs/some_id",
      headers: { "Authorization" => "Bearer invalid-token" }
    assert_response :unauthorized
  end

  test "GET /v1/blobs/:id does not allow a user to access other user's blobs" do
    post "/v1/blobs",
      params: @valid_params,
      headers: auth_headers,
      as: :json
    assert_response :no_content
    track_created_blob_file

    get "/v1/blobs/#{@valid_params[:id]}",
      headers: { "Authorization" => "Bearer 93367a826d78632eb54957f467e10fa0628213e2c1896fb0c37338f7fb9f4c26" }

    assert_response :not_found
  end

  test "successfully saves blob record and stores file in the FTP server" do
    provider = storage_providers(:uplink_ftp)
    ftp_headers = { "Authorization" => "Bearer f44319627c65ed15e80b36a9029a34c3eb3eb57cb2c13defa3fd8acf1b8ef7b4" }

    assert_difference -> { Blob.count }, 1 do
      post "/v1/blobs",
        params: @valid_params,
        headers: ftp_headers,
        as: :json
    end

    assert_response :no_content

    blob = Blob.last
    assert_equal @valid_params[:id], blob.external_id
    assert_equal users(:uplink_user), blob.user
    assert_equal provider, blob.storage_provider

    # Verify that we can retrieve the blob via GET /v1/blobs/:id successfully
    get "/v1/blobs/#{@valid_params[:id]}",
      headers: ftp_headers

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal @valid_params[:id], json_response["id"]
    assert_equal @valid_params[:data], json_response["data"]
    assert_equal "27", json_response["size"]
  end

  test "POST /v1/blobs returns 422 if storing the file fails with Storage::WriteDataError" do
    storage_provider = storage_providers(:acme_filesystem)
    mock_adapter = Storage::Filesystem.new(options: storage_provider.configuration, storage_key: "dummy_key")

    mock_adapter.stub(:store, ->(*args) { raise Storage::WriteDataError.new("dummy_key", "Simulated write failure") }) do
      Storage::Factory.stub(:build, mock_adapter) do
        assert_no_difference -> { Blob.count } do
          post "/v1/blobs",
            params: @valid_params,
            headers: auth_headers,
            as: :json
        end

        assert_response :unprocessable_entity
        json_response = JSON.parse(response.body)
        assert_includes json_response["error"], "Failed to store file"
        assert_includes json_response["error"], "Simulated write failure"
      end
    end
  end

  private

  def track_created_blob_file
    blob = Blob.last
    return unless blob

    provider = blob.storage_provider
    if provider.adapter_type == "filesystem"
      file_path = Rails.root.join(
        provider.configuration["storage_path"],
        blob.storage_key[0, 2],
        blob.storage_key[2, 2],
        blob.storage_key
      )
      @created_files << file_path
    end
  end

  def auth_headers
    { "Authorization" => "Bearer 6d4769052b644be4c3f96ee67faa4bbb8ab8aa8be46055f2cea1e513cec22d52" }
  end
end
