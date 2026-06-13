require "base64"

module V1
  class BlobsController < ApplicationController
    before_action :authenticate_user!

    def create
      Base64.strict_decode64(params[:data].to_s)

      head :no_content
    rescue ArgumentError
      render json: { error: "data must be a valid Base64 encoded string" }, status: :unprocessable_entity
    end

    private

    def authenticate_user!
      token = bearer_token
      api_token = token.present? && ApiToken.lookup(token)

      return if api_token

      render json: { error: "Unauthorized" }, status: :unauthorized
    end

    def bearer_token
      authorization = request.authorization.to_s
      match = authorization.match(/\ABearer\s+(.+)\z/)
      match && match[1]
    end
  end
end
