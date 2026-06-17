require "base64"

class BlobShowSerializer < BlobSerializer
  attr_reader :data

  def initialize(blob, data)
    super(blob)
    @data = data
  end

  def as_json(options = nil)
    super.merge(data: Base64.strict_encode64(data))
  end
end
