class BlobSerializer
  attr_reader :blob

  def initialize(blob)
    @blob = blob
  end

  def as_json(options = nil)
    {
      id: blob.external_id,
      size: blob.size_bytes.to_s,
      created_at: blob.created_at.utc.iso8601
    }
  end
end
