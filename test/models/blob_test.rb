require "test_helper"

class BlobTest < ActiveSupport::TestCase
  test "valid with user, storage provider, external id, storage key, size and checksum" do
    assert blobs(:readme_blob).valid?
  end

  test "invalid without a user" do
    blob = build_blob(user: nil)

    assert_not blob.valid?
    assert_includes blob.errors[:user], "must exist"
  end

  test "invalid without a storage provider" do
    blob = build_blob(storage_provider: nil)

    assert_not blob.valid?
    assert_includes blob.errors[:storage_provider], "must exist"
  end

  test "invalid without an external id" do
    blob = build_blob(external_id: nil)

    assert_not blob.valid?
    assert_includes blob.errors[:external_id], "can't be blank"
  end

  test "invalid with duplicate external id for the same user" do
    blob = build_blob(user: users(:jim), external_id: blobs(:readme_blob).external_id)

    assert_not blob.valid?
    assert_includes blob.errors[:external_id], "has already been taken"
  end

  test "valid with duplicate external id for another user" do
    blob = build_blob(user: users(:bob), external_id: blobs(:readme_blob).external_id)

    assert blob.valid?
  end

  test "generates storage key before validation on create" do
    blob = build_blob(storage_key: nil)

    assert_nil blob.storage_key
    assert blob.valid?
    assert_match(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/, blob.storage_key)
  end

  test "does not override provided storage key" do
    blob = build_blob(storage_key: "custom-storage-key")

    assert blob.valid?
    assert_equal "custom-storage-key", blob.storage_key
  end

  test "invalid with duplicate storage key" do
    blob = build_blob(storage_key: blobs(:readme_blob).storage_key)

    assert_not blob.valid?
    assert_includes blob.errors[:storage_key], "has already been taken"
  end

  test "invalid without size bytes" do
    blob = build_blob(size_bytes: nil)

    assert_not blob.valid?
    assert_includes blob.errors[:size_bytes], "can't be blank"
  end

  test "invalid with negative size bytes" do
    blob = build_blob(size_bytes: -1)

    assert_not blob.valid?
    assert_includes blob.errors[:size_bytes], "must be greater than or equal to 0"
  end

  test "invalid without checksum sha256" do
    blob = build_blob(checksum_sha256: nil)

    assert_not blob.valid?
    assert_includes blob.errors[:checksum_sha256], "can't be blank"
  end

  private

  def build_blob(attributes = {})
    Blob.new({
      user: users(:jim),
      storage_provider: storage_providers(:acme_filesystem),
      external_id: "uploads/new-file.txt",
      storage_key: "33333333-3333-4333-8333-333333333333",
      size_bytes: 512,
      checksum_sha256: "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08"
    }.merge(attributes))
  end
end
