class User < ApplicationRecord
  belongs_to :tenant
  has_many :api_tokens, dependent: :destroy

  validates :email, presence: true, uniqueness: { scope: :tenant_id }
end
