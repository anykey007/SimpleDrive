class Tenant < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :storage_providers, dependent: :destroy

  validates :name, presence: true
end
