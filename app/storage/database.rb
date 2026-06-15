module Storage
  class Database < Base
    def initialize(storage_key: nil)
      @storage_key = storage_key
    end

    def store(io:)
      raise ArgumentError, "storage_key is required" unless @storage_key

      BlobDataObject.create!(storage_key: @storage_key, data: io.read)

      @storage_key
    end

    def retrieve
      raise ArgumentError, "storage_key is required" unless @storage_key

      blob_data = BlobDataObject.find_by!(storage_key: @storage_key)

      StringIO.new(blob_data.data)
    end
  end
end
