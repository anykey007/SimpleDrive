module Storage
  class Database < Base
    def store(io:)
      BlobDataObject.create!(storage_key: storage_key, data: io.read)
      storage_key
    end

    def retrieve
      blob_data = BlobDataObject.find_by!(storage_key: storage_key)
      StringIO.new(blob_data.data)
    rescue ActiveRecord::RecordNotFound => e
      raise Storage::FileNotFoundError.new(storage_key, "Blob data object not found in the storage database", e)
    end
  end
end
