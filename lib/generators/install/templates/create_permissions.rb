class CreatePermissions < ActiveRecord::Migration[<%= ActiveRecord::Migration.current_version %>]
  def change
    create_table :permissions do |t|
      t.string :name, null: false

      t.timestamps
    end

    add_index :permissions, :name, unique: true
  end
end
