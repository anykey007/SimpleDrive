require "base64"
require "stringio"
require "digest"

module V1
  class BlobsController < ApplicationController
    before_action :authenticate_user!

    def create
      decoded_data = Base64.strict_decode64(params[:data].to_s)

      storage_provider = @current_user.default_storage_provider

      unless storage_provider
        render json: { error: "No active storage provider found" }, status: :unprocessable_entity
        return
      end

      blob = Blob.new(
        user: @current_user,
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
    rescue Storage::WriteDataError => e
      render json: { error: "Failed to store file: #{e.message}" }, status: :unprocessable_entity
    end

    def show
      blob = @current_user.blobs.find_by!(external_id: params[:id])
      data = read_data(blob)

      render json: {
        id: blob.external_id,
        data: Base64.strict_encode64(data),
        size: blob.size_bytes.to_s,
        created_at: blob.created_at.utc.iso8601
      }, status: :ok

    rescue ActiveRecord::RecordNotFound => e
      render json: { error: "Blob not found" }, status: :not_found
    rescue Storage::ReadDataError => e
      render json: { error: "File content is missing on storage server: #{e.message}" }, status: :not_found
    rescue => e
      render json: { error: "Failed to retrieve storage data: #{e.message}" }, status: :internal_server_error
    end

    private

    def read_data(blob)
      storage_provider = blob.storage_provider
      adapter = Storage::Factory.build(storage_provider, storage_key: blob.storage_key)

      io = adapter.retrieve
      io.read
    ensure
      io.close if io.respond_to?(:close)
    end
  end
end
