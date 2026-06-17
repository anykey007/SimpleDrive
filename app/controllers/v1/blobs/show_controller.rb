require "base64"

module V1
  module Blobs
    class ShowController < ApplicationController
      before_action :authenticate_user!

      def show
        blob = @current_user.blobs.where(status: :persisted).find_by!(external_id: params[:id])
        data = read_data(blob)

        render json: BlobShowSerializer.new(blob, data), status: :ok

      rescue ActiveRecord::RecordNotFound => e
        render json: { error: "Blob not found" }, status: :not_found
      rescue Storage::ReadDataError => e
        render json: { error: "File content is missing on storage server: #{e.message}" }, status: :not_found
      rescue => e
        render json: { error: "Failed to retrieve storage data: #{e.message}" }, status: :internal_server_error
      end

      private

      def read_data(blob)
        adapter = Storage::Factory.build(blob.storage_provider, storage_key: blob.storage_key)
        adapter.retrieve { |io| io.read }
      end
    end
  end
end
