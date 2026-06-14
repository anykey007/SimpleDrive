require "base64"
require "stringio"
require "digest"

module V1
  class BlobsController < ApplicationController
    before_action :authenticate_user!

    def create
      decoded_data = Base64.strict_decode64(params[:data].to_s)

      storage_provider = @api_token.user.tenant.storage_providers.active.first

      unless storage_provider
        render json: { error: "No active storage provider found" }, status: :unprocessable_entity
        return
      end

      blob = Blob.new(
        user: @api_token.user,
        storage_provider: storage_provider,
        external_id: params[:id],
        size_bytes: decoded_data.bytesize,
        checksum_sha256: Digest::SHA256.hexdigest(decoded_data)
      )

      if blob.valid?
        adapter = Storage::Factory.build(storage_provider, storage_key: blob.storage_key)
        adapter.store(io: StringIO.new(decoded_data))

        blob.save!
        head :no_content
      else
        render json: { errors: blob.errors.full_messages }, status: :unprocessable_entity
      end
    rescue ArgumentError
      render json: { error: "data must be a valid Base64 encoded string" }, status: :unprocessable_entity
    end

    private

    def authenticate_user!
      token = bearer_token
      @api_token = token.present? && ApiToken.lookup(token)

      return if @api_token

      render json: { error: "Unauthorized" }, status: :unauthorized
    end

    def bearer_token
      authorization = request.authorization.to_s
      match = authorization.match(/\ABearer\s+(.+)\z/)
      match && match[1]
    end
  end
end
