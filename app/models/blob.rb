require "securerandom"

class Blob < ApplicationRecord
  belongs_to :user
  belongs_to :storage_provider

  before_validation :generate_storage_key, on: :create

  enum :status, {
    pending: "pending",
    persisted: "persisted",
    failed: "failed"
  }, default: :pending, prefix: true

  validates :external_id, presence: true, uniqueness: { scope: :user_id }
  validates :storage_key, presence: true, uniqueness: true
  validates :size_bytes, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than: 1.megabyte }
  validates :checksum_sha256, presence: true
  validates :status, presence: true

  private

  def generate_storage_key
    self.storage_key ||= SecureRandom.uuid
  end
end
