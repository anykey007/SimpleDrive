require "net/ftp"
require "stringio"

module Storage
  class Ftp < Base
    def initialize(host: nil, port: nil, username: nil, password: nil, root_path: nil, storage_key: nil)
      @host = host || "localhost"
      @port = (port || 21).to_i
      @username = username
      @password = password
      @root_path = root_path
      @storage_key = storage_key
    end

    def store(io:)
      raise ArgumentError, "storage_key is required" unless @storage_key
      raise ArgumentError, "root_path is required" unless @root_path

      path = file_path
      dir = File.dirname(path)

      with_ftp do |ftp|
        mkdir_p(ftp, dir)
        ftp.storbinary("STOR #{path}", io, Net::FTP::DEFAULT_BLOCKSIZE)
      end

      path
    end

    def retrieve
      raise ArgumentError, "storage_key is required" unless @storage_key
      raise ArgumentError, "root_path is required" unless @root_path

      path = file_path
      data = String.new

      with_ftp do |ftp|
        ftp.retrbinary("RETR #{path}", Net::FTP::DEFAULT_BLOCKSIZE) do |block|
          data << block
        end
      end

      StringIO.new(data)

    rescue Net::FTPPermError => e
      raise unless e.message.start_with?("550")

      raise Errno::ENOENT, path
    end

    private

    def file_path
      @file_path ||= File.join(
        @root_path,
        @storage_key[0, 2],
        @storage_key[2, 2],
        @storage_key
      )
    end

    def with_ftp
      ftp = Net::FTP.new
      ftp.connect(@host, @port)
      ftp.login(@username, @password)
      ftp.passive = true
      yield ftp
    ensure
      ftp&.close if ftp && !ftp.closed?
    end

    def mkdir_p(ftp, path)
      parts = path.split("/").reject(&:empty?)
      current_path = ""
      parts.each do |part|
        current_path = "#{current_path}/#{part}"
        begin
          ftp.mkdir(current_path)
        rescue Net::FTPPermError
          # Ignore if directory already exists
        end
      end
    end
  end
end
