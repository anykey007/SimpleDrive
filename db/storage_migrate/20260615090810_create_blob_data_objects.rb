class CreateBlobDataObjects < ActiveRecord::Migration[8.1]
  def change
    create_table :blob_data_objects do |t|
      t.string :storage_key, null: false
      t.binary :data, null: false

      t.timestamps
    end

    add_index :blob_data_objects,
              :storage_key,
              unique: true
  end
end
