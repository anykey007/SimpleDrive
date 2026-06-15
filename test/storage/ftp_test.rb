require "test_helper"
require "stringio"

class Storage::FtpTest < ActiveSupport::TestCase
  setup do
    @provider = storage_providers(:four)
    @root_path = @provider.configuration[:root_path]
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
    expected_path = File.join(@root_path, @storage_key[0, 2], @storage_key[2, 2], @storage_key)
    assert_equal expected_path, stored_path

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
    assert_equal ["host", "password", "port", "root_path", "username"], error.missing_keys
  end

  test "raises Errno::ENOENT on retrieve if file is not found on FTP" do
    storage = Storage::Ftp.new(
      options: @provider.configuration,
      storage_key: "nonexistent_key_here_1234"
    )

    assert_raises(Errno::ENOENT) do
      storage.retrieve
    end
  end
end
