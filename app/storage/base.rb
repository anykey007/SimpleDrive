module Storage
  class Error < StandardError; end

  class ReadDataError < Error
    attr_reader :storage_key, :original_exception

    def initialize(storage_key, message = "File not found in storage", original_exception = nil)
      @storage_key = storage_key
      @original_exception = original_exception
      super("#{message} (key: #{storage_key})")
    end
  end

  class WriteDataError < Error
    attr_reader :storage_key, :original_exception

    def initialize(storage_key, message = "Failed to write file to storage", original_exception = nil)
      @storage_key = storage_key
      @original_exception = original_exception
      super("#{message} (key: #{storage_key})")
    end
  end

  class ConfigurationError < Error
    attr_reader :adapter_class, :missing_keys

    def initialize(adapter_class, missing_keys)
      @adapter_class = adapter_class
      @missing_keys = Array(missing_keys).map(&:to_s).sort
      super("Missing required options: #{@missing_keys.join(', ')} for #{@adapter_class}")
    end
  end

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

    protected

    def require_options!(*keys)
      missing_keys = keys.select do |key|
        value = options[key]
        value.nil? || (value.respond_to?(:empty?) && value.empty?)
      end

      if missing_keys.any?
        raise Storage::ConfigurationError.new(self.class.name, missing_keys)
      end
    end
  end
end
