class CreateBlobs < ActiveRecord::Migration[8.1]
  def change
    create_table :blobs do |t|
      t.references :user, null: false, foreign_key: true
      t.references :storage_provider, null: false, foreign_key: true
      t.string :external_id, null: false
      t.string :storage_key, null: false
      t.bigint :size_bytes, null: false
      t.string :checksum_sha256, null: false

      t.timestamps
    end

    add_index :blobs, [ :user_id, :external_id ], unique: true
    add_index :blobs, :storage_key, unique: true
  end
end
