require 'active_support'

module Rbacan
  module Permittable
    extend ActiveSupport::Concern

    included do
      has_many :user_roles,
               class_name: Rbacan.user_role_class,
               dependent:  :destroy
      accepts_nested_attributes_for :user_roles
      has_many :roles,
               class_name: Rbacan.role_class,
               through:    :user_roles

      # Returns users that have the given role (by name).
      scope :with_role, ->(role_name) {
        joins(:roles).where(Rbacan.role_table => { name: role_name.to_s })
      }

      # Returns users that have the given permission via any of their roles.
      scope :with_permission, ->(permission_name) {
        joins(roles: { role_permissions: :permission })
          .where(Rbacan.permission_table => { name: permission_name.to_s })
      }

      # Assigns a role to the user. Idempotent — safe to call multiple times.
      # Fix: was find_or_initialize_by (never persisted); now find_or_create_by.
      def assign_role(role_name)
        assigned_role = Rbacan.role_class.constantize.find_by_name(role_name.to_s)
        raise ArgumentError, "Role '#{role_name}' not found" unless assigned_role

        self.user_roles.find_or_create_by(role_id: assigned_role.id)
      end

      # Removes a role from the user.
      # Fix: was Rbacan::UserRole.where(user_id: ...) — now uses the scoped
      # association so it respects the configured class and any FK setup.
      def remove_role(role_name)
        removed_role = Rbacan.role_class.constantize.find_by_name(role_name.to_s)
        return unless removed_role

        self.user_roles.where(role_id: removed_role.id).destroy_all
      end

      # Returns true if the user has the named permission via any of their roles.
      # Fix: was two queries; now a single EXISTS query via association joins.
      def can?(permission_name)
        self.roles
            .joins(role_permissions: :permission)
            .where(Rbacan.permission_table => { name: permission_name.to_s })
            .exists?
      end

      # Returns true if the user has the named role.
      def has_role?(role_name)
        self.roles.where(name: role_name.to_s).exists?
      end

      # Returns true if the user has ANY of the listed roles.
      def has_any_role?(*role_names)
        self.roles.where(name: role_names.map(&:to_s)).exists?
      end

      # Returns true if the user has ALL of the listed permissions.
      # Uses a single query: counts distinct matching permissions and compares
      # to the requested set size.
      def can_all?(*permission_names)
        names = permission_names.map(&:to_s)
        self.roles
            .joins(role_permissions: :permission)
            .where(Rbacan.permission_table => { name: names })
            .select("#{Rbacan.permission_table}.name")
            .distinct
            .count == names.uniq.size
      end
    end
  end
end
