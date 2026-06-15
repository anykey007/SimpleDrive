require "test_helper"
require "fileutils"
require "stringio"
require "tmpdir"

class Storage::FilesystemTest < ActiveSupport::TestCase
  setup do
    @tmpdir = Dir.mktmpdir("simple-drive-storage")
    @storage_path = File.join(@tmpdir, "tenant-1")
  end

  teardown do
    FileUtils.remove_entry(@tmpdir) if @tmpdir && Dir.exist?(@tmpdir)
  end

  test "stores file content using sharded storage key path" do
    storage_key = "abcdef123456"
    @storage = Storage::Filesystem.new(options: { storage_path: @storage_path }, storage_key: storage_key)

    io = StringIO.new("Hello Simple Storage World!")

    stored_path = @storage.store(io: io)
    expected_path = File.join(@storage_path, "ab", "cd", storage_key)

    assert_equal expected_path, stored_path
    assert_path_exists expected_path
    assert_equal "Hello Simple Storage World!", File.binread(expected_path)
  end

  test "stores binary file content" do
    storage_key = "001122334455"
    content = "\x00\x01\x02binary".b

    @storage = Storage::Filesystem.new(options: { storage_path: @storage_path }, storage_key: storage_key)

    @storage.store(io: StringIO.new(content))

    assert_equal content, File.binread(File.join(@storage_path, "00", "11", storage_key))
  end

  test "retrieves stored file as readable binary io" do
    storage_key = "feedface"

    @storage = Storage::Filesystem.new(options: { storage_path: @storage_path }, storage_key: storage_key)
    @storage.store(io: StringIO.new("stored content"))

    retrieved = @storage.retrieve

    assert_equal "stored content", retrieved.read
  ensure
    retrieved&.close
  end

  test "raises Storage::ReadDataError when file does not exist on retrieve" do
    @storage = Storage::Filesystem.new(options: { storage_path: @storage_path }, storage_key: "missing-key")
    assert_raises(Storage::ReadDataError) do
      @storage.retrieve
    end
  end

  test "raises Storage::WriteDataError when writing fails on store" do
    @storage = Storage::Filesystem.new(options: { storage_path: @storage_path }, storage_key: "some-key")

    File.stub(:binwrite, ->(*args) { raise Errno::EACCES, "Permission denied" }) do
      error = assert_raises(Storage::WriteDataError) do
        @storage.store(io: StringIO.new("test"))
      end
      assert_equal "some-key", error.storage_key
      assert_kind_of Errno::EACCES, error.original_exception
    end
  end
end

class Storage::FilesystemInitializationTest < ActiveSupport::TestCase
  test "raises ArgumentError when storage_key is missing or nil" do
    assert_raises(ArgumentError) { Storage::Filesystem.new(options: { storage_path: "path" }) }
    assert_raises(ArgumentError) { Storage::Filesystem.new(options: { storage_path: "path" }, storage_key: nil) }
  end

  test "raises Storage::ConfigurationError when storage_path is missing or nil" do
    assert_raises(Storage::ConfigurationError) { Storage::Filesystem.new(storage_key: "key") }
    assert_raises(Storage::ConfigurationError) { Storage::Filesystem.new(options: nil, storage_key: "key") }
    assert_raises(Storage::ConfigurationError) { Storage::Filesystem.new(options: { storage_path: nil }, storage_key: "key") }
  end

  test "retrieves with storage path configured during initialization" do
    Dir.mktmpdir("simple-drive-storage") do |tmpdir|
      storage_path = File.join(tmpdir, "tenant-2")
      storage_key = "cafebabe"
      writer = Storage::Filesystem.new(options: { storage_path: storage_path }, storage_key: storage_key)
      writer.store(io: StringIO.new("configured path"))

      reader = Storage::Filesystem.new(options: { storage_path: storage_path }, storage_key: storage_key)
      retrieved = reader.retrieve

      assert_equal "configured path", retrieved.read
    ensure
      retrieved&.close
    end
  end
end
