require "test_helper"

class Storage::FactoryTest < ActiveSupport::TestCase
  test "builds a filesystem adapter successfully with valid storage provider" do
    provider = storage_providers(:one) # This is defined as 'filesystem' in fixtures
    assert_equal "filesystem", provider.adapter_type

    adapter = Storage::Factory.build(provider, storage_key: "abc123key")
    assert_instance_of Storage::Filesystem, adapter

    # Verify initialized path and key via public interface
    assert_equal "test_storage/one", adapter.options[:storage_path]
    assert_equal "abc123key", adapter.storage_key
  end

  test "builds filesystem adapter with symbol-keyed configurations" do
    # Create a mock/stub storage provider with symbol keys in configuration
    provider = StorageProvider.new(
      adapter_type: "filesystem",
      configuration: { storage_path: "storage/symbol_path" }
    )

    adapter = Storage::Factory.build(provider, storage_key: "symkey")
    assert_instance_of Storage::Filesystem, adapter
    assert_equal "storage/symbol_path", adapter.options[:storage_path]
    assert_equal "symkey", adapter.storage_key
  end

  test "builds an s3 adapter successfully with valid storage provider" do
    provider = StorageProvider.new(
      adapter_type: "s3",
      configuration: {
        "bucket" => "my-s3-bucket",
        "endpoint" => "http://localhost:9000",
        "access_key_id" => "minio",
        "secret_access_key" => "minio123456",
        "region" => "us-east-1",
        "force_path_style" => true
      }
    )

    adapter = Storage::Factory.build(provider, storage_key: "s3key")
    assert_instance_of Storage::S3, adapter
    assert_equal "my-s3-bucket", adapter.options[:bucket]
    assert_equal "s3key", adapter.storage_key
  end

  test "builds s3 adapter with symbol-keyed configurations" do
    provider = StorageProvider.new(
      adapter_type: "s3",
      configuration: {
        bucket: "my-s3-bucket-symbol",
        endpoint: "http://localhost:9000",
        access_key_id: "minio",
        secret_access_key: "minio123456",
        region: "us-east-1",
        force_path_style: true
      }
    )

    adapter = Storage::Factory.build(provider, storage_key: "s3key")
    assert_instance_of Storage::S3, adapter
    assert_equal "my-s3-bucket-symbol", adapter.options[:bucket]
    assert_equal "s3key", adapter.storage_key
  end

  test "builds a database adapter successfully with valid storage provider" do
    provider = storage_providers(:three)

    adapter = Storage::Factory.build(provider, storage_key: "dbkey")
    assert_instance_of Storage::Database, adapter
    assert_equal "dbkey", adapter.storage_key
  end

  test "builds an ftp adapter successfully with valid storage provider" do
    provider = storage_providers(:four)

    adapter = Storage::Factory.build(provider, storage_key: "ftpkey")
    assert_instance_of Storage::Ftp, adapter
    assert_equal "localhost", adapter.options[:host]
    assert_equal 21, adapter.options[:port]
    assert_equal "ftpuser", adapter.options[:username]
    assert_equal "ftppassword", adapter.options[:password]
    assert_equal "/test", adapter.options[:root_path]
    assert_equal "ftpkey", adapter.storage_key
  end

  test "raises ArgumentError when storage provider is nil" do
    error = assert_raises(ArgumentError) do
      Storage::Factory.build(nil)
    end
    assert_equal "Storage provider is required", error.message
  end

  test "raises ArgumentError when adapter type is unknown" do
    provider = StorageProvider.new(
      adapter_type: "unknown_adapter",
      configuration: { storage_path: "some_path" }
    )

    error = assert_raises(ArgumentError) do
      Storage::Factory.build(provider)
    end
    assert_equal "Unknown storage provider adapter type: unknown_adapter", error.message
  end
end
