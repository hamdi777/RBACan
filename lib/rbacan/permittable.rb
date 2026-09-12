require 'active_support'

module Rbacan
  module Permittable
    extend ActiveSupport::Concern

    included do
      has_many :user_roles,
               class_name: Rbacan.user_role_class,
               dependent: :destroy
      accepts_nested_attributes_for :user_roles
      has_many :roles,
               class_name: Rbacan.role_class,
               through: :user_roles

      # Returns users that have the given role (by name).
    scope :with_role, lambda { |role_name|
      Rbacan.ensure_legacy_mode!(:with_role)
        joins(:roles).where(Rbacan.role_table => { Rbacan.role_key => role_name.to_s })
      }

      # Returns users that have the given permission via any of their roles.
    scope :with_permission, lambda { |permission_name|
      Rbacan.ensure_legacy_mode!(:with_permission)
      joins(roles: { role_permissions: :permission })
          .where(Rbacan.permission_table => { Rbacan.permission_key => permission_name.to_s })
      }

      # Assigns a role to the user. Idempotent — safe to call multiple times.
      # When tenant_scoped is enabled, pass tenant_id: to scope the assignment.
    def assign_role(role_name, tenant_id: nil)
      Rbacan.ensure_legacy_mode!(:assign_role)
      assigned_role = Rbacan.role_class.constantize.find_by(Rbacan.role_key => role_name.to_s)
        raise ArgumentError, "Role '#{role_name}' not found" unless assigned_role

        attrs = { role_id: assigned_role.id }
        attrs[:tenant_id] = tenant_id if Rbacan.tenant_scoped
        user_roles.find_or_create_by(attrs)
      end

      # Removes a role from the user.
      # When tenant_scoped is enabled, pass tenant_id: to remove from a specific tenant.
    def remove_role(role_name, tenant_id: nil)
      Rbacan.ensure_legacy_mode!(:remove_role)
      removed_role = Rbacan.role_class.constantize.find_by(Rbacan.role_key => role_name.to_s)
        return unless removed_role

        scope = user_roles.where(role_id: removed_role.id)
        scope = scope.where(tenant_id: tenant_id) if Rbacan.tenant_scoped
        scope.destroy_all
      end

      # Returns true if the user has the named permission via any of their roles.
    def can?(permission_name)
      Rbacan.ensure_legacy_mode!(:can?)
      roles
          .joins(role_permissions: :permission)
        .where(Rbacan.permission_table => { Rbacan.permission_key => permission_name.to_s })
          .exists?
      end

      # Returns true if the user has the named permission in a specific tenant context.
      # Checks both global role assignments (tenant_id NULL) and tenant-specific ones.
    def can_in_tenant?(permission_name, tenant_id)
      Rbacan.ensure_legacy_mode!(:can_in_tenant?)
      roles
          .joins(role_permissions: :permission)
        .where(Rbacan.permission_table => { Rbacan.permission_key => permission_name.to_s })
          .where(Rbacan.user_role_table => { tenant_id: [tenant_id, nil] })
          .exists?
      end

      # Returns true if the user has the named role.
    def has_role?(role_name)
      Rbacan.ensure_legacy_mode!(:has_role?)
      roles.where(Rbacan.role_key => role_name.to_s).exists?
      end

      # Returns true if the user has the named role in a specific tenant context.
      # Checks both global role assignments (tenant_id NULL) and tenant-specific ones.
    def has_role_in_tenant?(role_name, tenant_id)
      Rbacan.ensure_legacy_mode!(:has_role_in_tenant?)
      user_roles
          .joins(:role)
        .where(Rbacan.role_table => { Rbacan.role_key => role_name.to_s })
          .where(Rbacan.user_role_table => { tenant_id: [tenant_id, nil] })
          .exists?
      end

      # Returns true if the user has ANY of the listed roles.
    def has_any_role?(*role_names)
      Rbacan.ensure_legacy_mode!(:has_any_role?)
      roles.where(Rbacan.role_key => role_names.map(&:to_s)).exists?
      end

      # Returns true if the user has ALL of the listed permissions.
    def can_all?(*permission_names)
      Rbacan.ensure_legacy_mode!(:can_all?)
      names = permission_names.map(&:to_s)
        roles
          .joins(role_permissions: :permission)
        .where(Rbacan.permission_table => { Rbacan.permission_key => names })
        .select("#{Rbacan.permission_table}.#{Rbacan.permission_key}")
          .distinct
          .count == names.uniq.size
      end

      # Returns roles assigned to this user for a specific tenant.
      # Includes global role assignments (tenant_id NULL).
    def roles_for_tenant(tenant_id)
      Rbacan.ensure_legacy_mode!(:roles_for_tenant)
      roles
          .where(Rbacan.user_role_table => { tenant_id: [tenant_id, nil] })
      end
    end
  end
end
