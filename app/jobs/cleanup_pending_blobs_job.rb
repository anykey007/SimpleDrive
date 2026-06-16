class CleanupPendingBlobsJob < ApplicationJob
  queue_as :default

  def perform
    # stale_blobs = Blob.where(status: :pending).where("created_at < ?", 2.hours.ago)
    #
    # stale_blobs.find_each do |blob|
    #   adapter = Storage::Factory.build(blob.storage_provider, storage_key: blob.storage_key)
    #   begin
    #     adapter.delete if adapter.respond_to?(:delete)
    #   rescue => e
    #     Rails.logger.error("Failed to clean up storage for blob #{blob.id}: #{e.message}")
    #   end
    #
    #   blob.destroy
    # end
  end
end
