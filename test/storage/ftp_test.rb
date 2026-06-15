require "test_helper"
require "stringio"

class Storage::FtpTest < ActiveSupport::TestCase
  setup do
    @provider = storage_providers(:uplink_ftp)
    @storage_key = "test_ftp_file_key"
  end

  test "stores and retrieves file content on FTP server" do
    storage = Storage::Ftp.new(
      options: @provider.configuration,
      storage_key: @storage_key
    )

    io = StringIO.new("Hello FTP World!")

    # Verify store returns the correct file path
    stored_path = storage.store(io: io)
    assert_equal "/test/uplink/te/st/test_ftp_file_key", stored_path

    # Verify retrieve successfully fetches the content
    retrieved = storage.retrieve
    assert_equal "Hello FTP World!", retrieved.read
  ensure
    retrieved&.close
  end

  test "raises ArgumentError when storage_key is missing" do
    assert_raises(ArgumentError) do
      Storage::Ftp.new(
        options: @provider.configuration,
        storage_key: nil
      )
    end

    assert_raises(ArgumentError) do
      Storage::Ftp.new(
        options: @provider.configuration
      )
    end
  end

  test "raises Storage::ConfigurationError when root_path is missing" do
    assert_raises(Storage::ConfigurationError) do
      Storage::Ftp.new(
        options: @provider.configuration.merge(root_path: nil),
        storage_key: @storage_key
      )
    end

    assert_raises(Storage::ConfigurationError) do
      Storage::Ftp.new(
        options: @provider.configuration.except(:root_path),
        storage_key: @storage_key
      )
    end
  end

  test "raises Storage::ConfigurationError when multiple options are missing" do
    error = assert_raises(Storage::ConfigurationError) do
      Storage::Ftp.new(
        options: {},
        storage_key: @storage_key
      )
    end
    assert_equal [ "host", "password", "port", "root_path", "username" ], error.missing_keys
  end

  test "raises Storage::ReadDataError on retrieve if file is not found on FTP" do
    storage = Storage::Ftp.new(
      options: @provider.configuration,
      storage_key: "nonexistent_key_here_1234"
    )

    assert_raises(Storage::ReadDataError) do
      storage.retrieve
    end
  end

  test "raises Storage::WriteDataError when writing fails on FTP store" do
    storage = Storage::Ftp.new(
      options: @provider.configuration,
      storage_key: @storage_key
    )

    storage.stub(:with_ftp, ->(*args) { raise Net::FTPTempError, "421 Service not available" }) do
      error = assert_raises(Storage::WriteDataError) do
        storage.store(io: StringIO.new("test"))
      end
      assert_equal @storage_key, error.storage_key
      assert_kind_of Net::FTPTempError, error.original_exception
    end
  end
end
