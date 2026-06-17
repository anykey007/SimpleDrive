require "test_helper"

class RequestSizeLimiterTest < ActiveSupport::TestCase
  setup do
    @app = ->(env) { [ 200, { "Content-Type" => "text/plain" }, [ "OK" ] ] }
  end

  test "allows requests smaller than the limit" do
    middleware = RequestSizeLimiter.new(@app, max_size: 100)
    env = {
      "CONTENT_LENGTH" => "50",
      "rack.input" => StringIO.new("a" * 50)
    }
    status, headers, body = middleware.call(env)
    assert_equal 200, status
    assert_equal [ "OK" ], body
  end

  test "blocks requests larger than the limit by Content-Length" do
    middleware = RequestSizeLimiter.new(@app, max_size: 100)
    env = {
      "CONTENT_LENGTH" => "150",
      "rack.input" => StringIO.new("a" * 150)
    }
    status, headers, body = middleware.call(env)
    assert_equal 413, status
    assert_equal "application/json", headers["Content-Type"]
    assert_equal [ { error: "Payload Too Large", max_allowed_bytes: 100 }.to_json ], body
  end
end
