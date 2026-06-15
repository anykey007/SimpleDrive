require_dependency Rails.root.join("lib/s3_client").to_s

module Storage
  class S3 < Base
    def initialize(storage_key:, options: {})
      super(storage_key: storage_key, options: options)
      require_options!(:bucket, :access_key_id, :secret_access_key, :endpoint)
    end

    def client
      @client ||= S3Client.new(
        bucket: options[:bucket],
        access_key_id: options[:access_key_id],
        secret_access_key: options[:secret_access_key],
        endpoint: options[:endpoint],
        region: options[:region],
        force_path_style: options[:force_path_style].nil? ? true : options[:force_path_style]
      )
    end

    def store(io:)
      client.put_object(storage_key, io)
      storage_key
    rescue => e
      raise Storage::WriteDataError.new(storage_key, "Failed to write object to S3 bucket", e)
    end

    def retrieve
      response = client.get_object(storage_key)
      StringIO.new(response.body)
    rescue => e
      if e.message.include?("code 404")
        raise Storage::ReadDataError.new(storage_key, "Object not found in S3 bucket", e)
      else
        raise e
      end
    end
  end
end
