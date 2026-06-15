class BlobDataObject < ActiveRecord::Base
  establish_connection :storage

  validates :storage_key, presence: true, uniqueness: true
  validates :data, presence: true
end
