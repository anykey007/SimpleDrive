require_dependency Rails.root.join("lib/s3_client").to_s

module Storage
  class S3 < Base
    attr_reader :bucket_name, :storage_key

    def initialize(bucket: nil, access_key_id: nil, secret_access_key: nil, endpoint: nil, region: "us-east-1", force_path_style: true, storage_key: nil)
      @bucket_name = bucket
      @storage_key = storage_key
      @access_key_id = access_key_id
      @secret_access_key = secret_access_key
      @endpoint = endpoint
      @region = region || "us-east-1"
      @force_path_style = force_path_style.nil? ? true : force_path_style
    end

    def client
      @client ||= S3Client.new(
        bucket: @bucket_name,
        access_key_id: @access_key_id,
        secret_access_key: @secret_access_key,
        endpoint: @endpoint,
        region: @region,
        force_path_style: @force_path_style
      )
    end

    def store(io:)
      raise ArgumentError, "storage_key is required" unless storage_key
      raise ArgumentError, "bucket is required" unless bucket_name

      client.put_object(storage_key, io)
      storage_key
    end

    def retrieve
      raise ArgumentError, "storage_key is required" unless storage_key
      raise ArgumentError, "bucket is required" unless bucket_name

      response = client.get_object(storage_key)
      StringIO.new(response.body)
    end
  end
end
