module Storage
  class Base
    attr_reader :storage_key, :options

    def initialize(storage_key:, options: {})
      raise ArgumentError, "storage_key is required" if storage_key.nil?
      @storage_key = storage_key
      @options = (options || {}).with_indifferent_access
    end

    def store(*)
      raise NotImplementedError, "#{self.class} must implement #store"
    end

    def retrieve(*)
      raise NotImplementedError, "#{self.class} must implement #retrieve"
    end
  end
end
