module Storage
  class Database < Base
    Storage.register :database, self

    def store(io: nil)
      data = if block_given?
               temp_io = StringIO.new
               yield temp_io
               temp_io.string
             else
               io.read
             end

      BlobDataObject.create!(storage_key: storage_key, data: data)
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
