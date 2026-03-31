class CreateRolePermissions < ActiveRecord::Migration[<%= ActiveRecord::Migration.current_version %>]
  def change
    create_table :role_permissions do |t|
      t.references :role,       null: false, index: true, foreign_key: { to_table: :roles,       on_delete: :cascade }
      t.references :permission, null: false, index: true, foreign_key: { to_table: :permissions, on_delete: :cascade }

      t.timestamps
    end

    add_index :role_permissions, [:role_id, :permission_id], unique: true
  end
end
