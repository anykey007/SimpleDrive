require_dependency Rails.root.join("lib/s3_client").to_s

module Storage
  class S3 < Base
    required_options :bucket, :access_key_id, :secret_access_key, :endpoint
    Storage.register :s3, self

    def client
      @client ||= S3Client.new(
        bucket: options[:bucket],
        access_key_id: options[:access_key_id],
        secret_access_key: options[:secret_access_key],
        endpoint: options[:endpoint],
        region: options[:region]
      )
    end

    def store(io: nil)
      if block_given?
        temp_io = StringIO.new
        yield temp_io
        temp_io.rewind
        client.put_object(storage_key, temp_io)
      else
        client.put_object(storage_key, io)
      end
      storage_key
    rescue => e
      raise Storage::WriteDataError.new(storage_key, "Failed to write object to S3 bucket", e)
    end

    def retrieve(&block)
      response = client.get_object(storage_key)
      Storage.to_io(response.body, &block)
    rescue => e
      if e.message.include?("code 404")
        raise Storage::ReadDataError.new(storage_key, "Object not found in S3 bucket", e)
      else
        raise e
      end
    end
  end
end
