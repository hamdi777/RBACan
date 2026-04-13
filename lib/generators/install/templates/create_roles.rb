class CreateRoles < ActiveRecord::Migration[<%= ActiveRecord::Migration.current_version %>]
  def change
    create_table :roles<%= ", id: :uuid" if primary_key_type == :uuid %> do |t|
      t.string :name, null: false
<% if tenant_scoped? %>
      t.references :tenant, null: true, type: :<%= primary_key_type %>, index: true
<% end %>

      t.timestamps
    end
<% if tenant_scoped? %>

    add_index :roles, :name, unique: true, where: "tenant_id IS NULL", name: "index_roles_on_name_global"
    add_index :roles, [:tenant_id, :name], unique: true, name: "index_roles_on_tenant_id_and_name"
<% else %>

    add_index :roles, :name, unique: true
<% end %>
  end
end
