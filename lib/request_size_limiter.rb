class RequestSizeLimiter
  # Default limit set to 5MB, which is plenty for 1MB binary file + base64 overhead + metadata,
  # but small enough to prevent malicious large uploads.
  DEFAULT_MAX_SIZE = 5 * 1024 * 1024

  def initialize(app, max_size: nil)
    @app = app
    @max_size = max_size
  end

  def max_size
    ENV["MAX_REQUEST_SIZE_BYTES"]&.to_i || @max_size || DEFAULT_MAX_SIZE
  end

  def call(env)
    content_length = env['CONTENT_LENGTH'].to_i

    if content_length > max_size
      return [
        413,
        { 'Content-Type' => 'application/json' },
        [{ error: 'Payload Too Large', max_allowed_bytes: max_size }.to_json]
      ]
    end

    @app.call(env)
  end
end
