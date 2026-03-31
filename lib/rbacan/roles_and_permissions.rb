module Rbacan
  module RolesAndPermissions

    # Creates roles by name. Idempotent — skips existing ones.
    def self.create_roles(roles)
      roles.each do |role|
        Rbacan.role_class.constantize.find_or_create_by(name: role.to_s)
      end
    end

    # Creates permissions by name. Idempotent — skips existing ones.
    def self.create_permissions(permissions)
      permissions.each do |permission|
        Rbacan.permission_class.constantize.find_or_create_by(name: permission.to_s)
      end
    end

    # Assigns a list of permissions to a role. Idempotent — skips duplicates.
    def self.assign_permissions_to_role(role_name, permissions)
      chosen_role = Rbacan.role_class.constantize.find_by_name(role_name.to_s)
      return unless chosen_role

      permissions.each do |permission|
        given_permission = Rbacan.permission_class.constantize.find_by_name(permission.to_s)
        next unless given_permission

        Rbacan.role_permission_class.constantize.find_or_create_by(
          role_id:       chosen_role.id,
          permission_id: given_permission.id
        )
      end
    end
  end
end
