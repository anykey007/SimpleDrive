class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.references :tenant, null: false, foreign_key: true
      t.string :email, null: false

      t.timestamps
    end

    add_index :users, [ :tenant_id, :email ], unique: true
  end
end
