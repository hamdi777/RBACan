class CreateUserRoles < ActiveRecord::Migration[<%= ActiveRecord::Migration.current_version %>]
  def change
    create_table :user_roles<%= ", id: :uuid" if primary_key_type == :uuid %> do |t|
      t.references :role, null: false, type: :<%= primary_key_type %>, index: true, foreign_key: { to_table: :roles, on_delete: :cascade }
      t.references :user, null: false, type: :<%= primary_key_type %>, index: true
<% if tenant_scoped? %>
      t.references :tenant, null: true, type: :<%= primary_key_type %>, index: true
<% end %>

      t.timestamps
    end
<% if tenant_scoped? %>

    add_index :user_roles, [:user_id, :role_id, :tenant_id], unique: true, name: "index_user_roles_unique"
<% else %>

    add_index :user_roles, [:user_id, :role_id], unique: true
<% end %>
  end
end
