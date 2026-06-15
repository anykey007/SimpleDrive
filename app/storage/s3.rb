require_dependency Rails.root.join("lib/s3_client").to_s

module Storage
  class S3 < Base
    attr_reader :bucket_name

    def initialize(bucket:, storage_key:, access_key_id: nil, secret_access_key: nil, endpoint: nil, region: "us-east-1", force_path_style: true)
      super(storage_key: storage_key)
      raise ArgumentError, "bucket is required" if bucket.nil?

      @bucket_name = bucket
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
      client.put_object(storage_key, io)
      storage_key
    end

    def retrieve
      response = client.get_object(storage_key)
      StringIO.new(response.body)
    end
  end
end
