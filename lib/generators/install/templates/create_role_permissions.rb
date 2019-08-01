class CreateRolePermissions < ActiveRecord::Migration[5.2]
    def change
        create_table :role_permissions do |t|
            t.references :role, index: true, foreign_key: {on_delete: :cascade}
            t.references :permission, index: true,  foreign_key: {on_delete: :cascade}
            t.timestamps
        end
    end
end
