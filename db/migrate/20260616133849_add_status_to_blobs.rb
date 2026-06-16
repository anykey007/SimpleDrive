class AddStatusToBlobs < ActiveRecord::Migration[8.1]
  def change
    add_column :blobs, :status, :string, default: "pending", null: false
  end
end
