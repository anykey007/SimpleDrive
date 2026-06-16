require "base64"
require "stringio"
require "digest"

module V1
  module Blobs
    class CreateController < ApplicationController
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
          checksum_sha256: Digest::SHA256.hexdigest(decoded_data),
          status: :pending
        )

        if blob.save
          persist_data(blob, decoded_data)
        else
          render json: { errors: blob.errors.full_messages }, status: :unprocessable_entity
        end
      rescue ArgumentError
        render json: { error: "data must be a valid Base64 encoded string" }, status: :unprocessable_entity
      rescue Storage::WriteDataError => e
        render json: { error: "Failed to store file: #{e.message}" }, status: :unprocessable_entity
      end

      private

      def persist_data(blob, data)
        adapter = Storage::Factory.build(blob.storage_provider, storage_key: blob.storage_key)
        adapter.store(io: Storage.to_io(data))

        blob.status_persisted!
        render json: {
          id: blob.external_id,
          size: blob.size_bytes.to_s,
          created_at: blob.created_at.utc.iso8601
        }, status: :created
      rescue => e
        blob.status_failed!
        raise e
      end
    end
  end
end
