class CreateStorageProviders < ActiveRecord::Migration[8.1]
  def change
    create_table :storage_providers do |t|
      t.references :tenant, null: false, foreign_key: true
      t.string :name, null: false
      t.string :adapter_type, null: false
      t.jsonb :configuration, null: false, default: {}
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :storage_providers, [ :tenant_id, :name ], unique: true
  end
end
