require "base64"

module V1
  module Blobs
    class ShowController < ApplicationController
      before_action :authenticate_user!

      def show
        blob = @current_user.blobs.where(status: :persisted).find_by!(external_id: params[:id])
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
end
