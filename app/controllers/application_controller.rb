class ApplicationController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods

  private

  def authenticate_user!
    authenticate_with_http_token do |token, options|
      @current_user = ApiToken.lookup(token)&.user
    end || render_unauthorized
  end

  def render_unauthorized
    render json: { error: "Unauthorized" }, status: :unauthorized
  end
end
