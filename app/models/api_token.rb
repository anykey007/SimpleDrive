class ApiToken < ApplicationRecord
  belongs_to :user

  validates :token_digest, presence: true, uniqueness: true

  def self.digest(token)
    Digest::SHA256.hexdigest(token)
  end

  def self.lookup(token)
    find_by(token_digest: digest(token))
  end
end
