class CreateUserRoles < ActiveRecord::Migration[<%= ActiveRecord::Migration.current_version %>]
  def change
    create_table :user_roles do |t|
      t.references :role, null: false, index: true, foreign_key: { to_table: :roles, on_delete: :cascade }
      t.bigint :user_id,  null: false

      t.timestamps
    end

    add_index :user_roles, :user_id
    add_index :user_roles, [:user_id, :role_id], unique: true
  end
end
