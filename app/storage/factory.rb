module Storage
  class Factory
    def self.build(storage_provider, storage_key: nil)
      raise ArgumentError, "Storage provider is required" if storage_provider.nil?

      adapter_class = Storage.adapter_class_for(storage_provider.adapter_type)

      adapter_class.new(
        storage_key: storage_key,
        options: storage_provider.configuration
      )
    end
  end
end
