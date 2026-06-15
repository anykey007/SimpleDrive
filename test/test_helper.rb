ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/mock"
require "base64"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
    def auth_header(user)
      tokens = {
        "jim@acme.test" => "6d4769052b644be4c3f96ee67faa4bbb8ab8aa8be46055f2cea1e513cec22d52",
        "bob@globex.test" => "93367a826d78632eb54957f467e10fa0628213e2c1896fb0c37338f7fb9f4c26",
        "sarah@cyberdyne.test" => "d88214fa3ca59d332d78632eb54957f467e10fa0628213e2c1896fb0c37338ff",
        "user@uplink.test" => "f44319627c65ed15e80b36a9029a34c3eb3eb57cb2c13defa3fd8acf1b8ef7b4"
      }
      token = tokens[user.email]
      raise "No token found for user: #{user.email}" unless token
      { "Authorization" => "Bearer #{token}" }
    end

    def valid_params
      {
        id: "any_valid_string_or_identifier",
        data: Base64.strict_encode64("Hello Simple Storage World!")
      }
    end
  end
end
