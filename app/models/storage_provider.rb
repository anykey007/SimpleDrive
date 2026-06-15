class StorageProvider < ApplicationRecord
  belongs_to :tenant
  has_many :blobs, dependent: :destroy

  scope :active, -> { where(active: true) }

  validates :name, presence: true, uniqueness: { scope: :tenant_id }
  validates :adapter_type, presence: true

  def configuration
    (super || {}).with_indifferent_access
  end
end
