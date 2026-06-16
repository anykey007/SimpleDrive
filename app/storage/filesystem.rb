require "fileutils"

module Storage
  class Filesystem < Base
    def initialize(storage_key:, options: {})
      super(storage_key: storage_key, options: options)
      require_options!(:storage_path)
    end

    def store(io: nil)
      FileUtils.mkdir_p(File.dirname(file_path))

      if block_given?
        File.open(file_path, "wb") do |file|
          yield file
        end
      else
        File.binwrite(file_path, io.read)
      end

      file_path
    rescue => e
      raise Storage::WriteDataError.new(storage_key, "Failed to write file to local filesystem", e)
    end

    def retrieve(&block)
      if block_given?
        File.open(file_path, "rb", &block)
      else
        File.open(file_path, "rb")
      end
    rescue Errno::ENOENT => e
      raise Storage::ReadDataError.new(storage_key, "File not found on local filesystem", e)
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
