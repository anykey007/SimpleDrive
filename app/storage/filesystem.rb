require "fileutils"

module Storage
  class Filesystem < Base
    def initialize(storage_key:, options: {})
      super(storage_key: storage_key, options: options)
      require_options!(:storage_path)
    end

    def store(io:)
      FileUtils.mkdir_p(File.dirname(file_path))

      File.binwrite(file_path, io.read)

      file_path
    end

    def retrieve
      File.open(file_path, "rb")
    end

    private

    def file_path
      @file_path ||= File.join(
        options[:storage_path],
        storage_key[0, 2],
        storage_key[2, 2],
        storage_key
      )
    end
  end
end
