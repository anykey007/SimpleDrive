require "simplecov"
SimpleCov.start "rails" do
  add_filter "/bin/"
  add_filter "/db/"
  add_filter "/test/"
end

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/mock"
require "base64"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    # parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
    def auth_header(token)
      { "Authorization" => "Bearer #{token}" }
    end

    def valid_params
      {
        id: "any_valid_string_or_identifier",
        data: Base64.strict_encode64("Hello Simple Storage World!")
      }
    end

    def assert_json_response(response, params, check_data: true)
      json_response = JSON.decode(response.body)
      assert_equal params[:id], json_response["id"]
      assert_match(/\A\d+\z/, json_response["size"])
      assert_match(/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/, json_response["created_at"])
      assert_equal(params[:data], json_response["data"]) if check_data
    end
  end
end
