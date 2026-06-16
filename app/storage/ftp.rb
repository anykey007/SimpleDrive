require "net/ftp"
require "stringio"

module Storage
  class Ftp < Base
    required_options :host, :port, :username, :password, :root_path
    Storage.register :ftp, self

    def store(io: nil)
      path = file_path
      dir = File.dirname(path)

      with_ftp do |ftp|
        mkdir_p(ftp, dir)
        if block_given?
          temp_io = StringIO.new
          yield temp_io
          temp_io.rewind
          ftp.storbinary("STOR #{path}", temp_io, Net::FTP::DEFAULT_BLOCKSIZE)
        else
          ftp.storbinary("STOR #{path}", io, Net::FTP::DEFAULT_BLOCKSIZE)
        end
      end

      path
    rescue => e
      raise Storage::WriteDataError.new(storage_key, "Failed to write file to FTP server", e)
    end

    def retrieve(&block)
      path = file_path
      data = String.new

      with_ftp do |ftp|
        ftp.retrbinary("RETR #{path}", Net::FTP::DEFAULT_BLOCKSIZE) do |block|
          data << block
        end
      end

      Storage.to_io(data, &block)

    rescue Net::FTPPermError => e
      raise unless e.message.start_with?("550")

      raise Storage::ReadDataError.new(storage_key, "File not found on FTP server", e)
    end

    private

    def file_path
      @file_path ||= File.join(
        options[:root_path],
        storage_key[0, 2],
        storage_key[2, 2],
        storage_key
      )
    end

    def with_ftp
      ftp = Net::FTP.new
      ftp.connect(options[:host], options[:port])
      ftp.login(options[:username], options[:password])
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
