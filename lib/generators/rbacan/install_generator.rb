require 'rails/generators'
require 'rails/generators/migration'

module Rbacan
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      include Rails::Generators::Migration
      source_root File.expand_path('../install/templates', __dir__)
      desc 'Add the migrations for roles and permissions'

      def self.next_migration_number(path)
        next_migration_number = current_migration_number(path) + 1
        ActiveRecord::Migration.next_migration_number(next_migration_number)
      end

      def copy_migrations
        migration_template 'create_permissions.rb', 'db/migrate/create_permissions.rb'
        migration_template 'create_roles.rb', 'db/migrate/create_roles.rb'
        migration_template 'create_role_permissions.rb', 'db/migrate/create_role_permissions.rb'
        migration_template 'create_user_roles.rb', 'db/migrate/create_user_roles.rb'
      end

      def copy_seed
        copy_file 'copy_to_seeds.rb', 'db/copy_to_seeds.rb'
      end

      def copy_initializer
        copy_file 'rbacan.rb', 'config/initializers/rbacan.rb'
      end

      private

      # Resolves the primary key type for migration templates.
      # Checks the explicit Rbacan config first, then the Rails generator config.
      def primary_key_type
        configured = Rbacan.primary_key_type
        configured ||= begin
          Rails.configuration.generators.options.dig(:active_record, :primary_key_type)
        rescue StandardError
          nil
        end
        configured || :bigint
      end

      # Whether tenant scoping is enabled.
      def tenant_scoped?
        Rbacan.tenant_scoped
      end
    end
  end
end
