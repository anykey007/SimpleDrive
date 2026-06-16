module Storage
  class Database < Base
    def store(io:)
      BlobDataObject.create!(storage_key: storage_key, data: io.read)
      storage_key
    rescue => e
      raise Storage::WriteDataError.new(storage_key, "Failed to write blob data object to database", e)
    end

    def retrieve(&block)
      blob_data = BlobDataObject.find_by!(storage_key: storage_key)
      Storage.to_io(blob_data.data, &block)
    rescue ActiveRecord::RecordNotFound => e
      raise Storage::ReadDataError.new(storage_key, "Blob data object not found in the storage database", e)
    end
  end
end
