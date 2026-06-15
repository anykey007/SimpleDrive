module Storage
  class Factory
    def self.build(storage_provider, storage_key: nil)
      raise ArgumentError, "Storage provider is required" if storage_provider.nil?

      adapter_class = case storage_provider.adapter_type.to_s
                      when "filesystem" then Storage::Filesystem
                      when "s3"         then Storage::S3
                      when "database"   then Storage::Database
                      when "ftp"        then Storage::Ftp
                      else
                        raise ArgumentError, "Unknown storage provider adapter type: #{storage_provider.adapter_type}"
                      end

      adapter_class.new(
        storage_key: storage_key,
        options: storage_provider.configuration
      )
    end
  end
end
