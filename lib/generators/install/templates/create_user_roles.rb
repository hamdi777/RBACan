class CreateUserRoles < ActiveRecord::Migration[5.2]
    def change
        create_table :user_roles do |t|
            t.references :role, index: true, foreign_key: {on_delete: :cascade}
            t.references :user, index: true, foreign_key: {on_delete: :cascade}
      
            t.timestamps
        end
    end
end
