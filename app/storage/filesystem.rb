require "fileutils"

module Storage
  class Filesystem < Base
    def initialize(storage_path: nil, storage_key: nil)
      @storage_path = storage_path
      @storage_key = storage_key
    end

    def store(io:)
      FileUtils.mkdir_p(File.dirname(file_path))

      File.binwrite(file_path, io.read)

      file_path
    end

    def retrieve
      raise ArgumentError, "file_path is required" unless file_path

      File.open(file_path, "rb")
    end

    private

    def file_path
      @file_path ||= File.join(
        @storage_path,
        @storage_key[0, 2],
        @storage_key[2, 2],
        @storage_key
      )
    end
  end
end
