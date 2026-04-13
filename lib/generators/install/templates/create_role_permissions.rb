class CreateRolePermissions < ActiveRecord::Migration[<%= ActiveRecord::Migration.current_version %>]
  def change
    create_table :role_permissions<%= ", id: :uuid" if primary_key_type == :uuid %> do |t|
      t.references :role,       null: false, type: :<%= primary_key_type %>, index: true, foreign_key: { to_table: :roles,       on_delete: :cascade }
      t.references :permission, null: false, type: :<%= primary_key_type %>, index: true, foreign_key: { to_table: :permissions, on_delete: :cascade }

      t.timestamps
    end

    add_index :role_permissions, [:role_id, :permission_id], unique: true
  end
end
