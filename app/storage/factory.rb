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
      else
        raise ArgumentError, "Unknown storage provider adapter type: #{storage_provider.adapter_type}"
      end
    end
  end
end
