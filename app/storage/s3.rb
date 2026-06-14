require "aws-sdk-s3"

module Storage
  class S3 < Base
    attr_reader :bucket_name, :storage_key

    def initialize(bucket:, access_key_id:, secret_access_key:, endpoint:, region:, force_path_style:, storage_key:)
      @bucket_name = bucket
      @storage_key = storage_key
      @client_options = { }
      @client_options[:access_key_id] = access_key_id if access_key_id
      @client_options[:secret_access_key] = secret_access_key if secret_access_key
      @client_options[:endpoint] = endpoint if endpoint
      @client_options[:force_path_style] = force_path_style if force_path_style
      @client_options[:region] = region if region
    end

    def client
      @client ||= Aws::S3::Client.new(@client_options)
    end

    def store(io:)
      raise ArgumentError, "storage_key is required" unless storage_key
      raise ArgumentError, "bucket is required" unless bucket_name

      ensure_bucket_exists!

      client.put_object(
        bucket: bucket_name,
        key: storage_key,
        body: io
      )
      storage_key
    end

    def retrieve
      raise ArgumentError, "storage_key is required" unless storage_key
      raise ArgumentError, "bucket is required" unless bucket_name

      response = client.get_object(
        bucket: bucket_name,
        key: storage_key
      )
      response.body
    end

    private

    def ensure_bucket_exists!
      begin
        client.head_bucket(bucket: bucket_name)
      rescue Aws::S3::Errors::NotFound, Aws::S3::Errors::NoSuchBucket
        client.create_bucket(bucket: bucket_name)
      rescue => e
        begin
          client.create_bucket(bucket: bucket_name)
        rescue => _create_error
          # Let the put_object try anyway and fail if it really can't write
        end
      end
    end
  end
end
