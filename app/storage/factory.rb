module Storage
  class Factory
    def self.build(storage_provider, storage_key: nil)
      raise ArgumentError, "Storage provider is required" if storage_provider.nil?

      case storage_provider.adapter_type.to_s
      when "filesystem"
        config = storage_provider.configuration || {}
        storage_path = config["storage_path"] || config[:storage_path]

        Storage::Filesystem.new(
          storage_path: storage_path,
          storage_key: storage_key
        )
      when "s3"
        config = storage_provider.configuration || {}
        Storage::S3.new(
          bucket: config["bucket"] || config[:bucket],
          access_key_id: config["access_key_id"] || config[:access_key_id],
          secret_access_key: config["secret_access_key"] || config[:secret_access_key],
          endpoint: config["endpoint"] || config[:endpoint],
          region: config["region"] || config[:region],
          force_path_style: config["force_path_style"].nil? ? config[:force_path_style] : config["force_path_style"],
          storage_key: storage_key
        )
      when "database"
        Storage::Database.new(
          storage_key: storage_key
        )
      when "ftp"
        config = storage_provider.configuration || {}
        Storage::Ftp.new(
          host: config["host"] || config[:host],
          port: config["port"] || config[:port],
          username: config["username"] || config[:username],
          password: config["password"] || config[:password],
          root_path: config["root_path"] || config[:root_path],
          storage_key: storage_key
        )
      else
        raise ArgumentError, "Unknown storage provider adapter type: #{storage_provider.adapter_type}"
      end
    end
  end
end
