require "bundler/setup"

require "active_record"

ActiveRecord::Base.establish_connection(
  adapter:  "sqlite3",
  database: ":memory:"
)

ActiveRecord::Schema.define do
  create_table :roles, force: true do |t|
    t.string :name, null: false
    t.timestamps null: false
  end
  add_index :roles, :name, unique: true

  create_table :permissions, force: true do |t|
    t.string :name, null: false
    t.timestamps null: false
  end
  add_index :permissions, :name, unique: true

  create_table :role_permissions, force: true do |t|
    t.integer :role_id,       null: false
    t.integer :permission_id, null: false
    t.timestamps null: false
  end
  add_index :role_permissions, [:role_id, :permission_id], unique: true

  create_table :user_roles, force: true do |t|
    t.integer :role_id, null: false
    t.integer :user_id, null: false
    t.timestamps null: false
  end
  add_index :user_roles, [:user_id, :role_id], unique: true

  create_table :users, force: true do |t|
    t.string :name
    t.timestamps null: false
  end
end

require "rbacan"

# Manually load engine models (no Rails autoloader in the test env).
require "rbacan/engine"
Dir[File.expand_path("../../app/models/**/*.rb", __FILE__)].sort.each { |f| require f }

# Minimal User model that includes the Permittable concern.
class User < ActiveRecord::Base
  include Rbacan::Permittable
end

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Wrap each example in a transaction and roll it back — no database_cleaner needed.
  config.around(:each) do |example|
    ActiveRecord::Base.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  end
end
