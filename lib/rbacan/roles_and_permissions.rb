module Rbacan
    module RolesAndPermissions

        attr_reader :test_method
        
        def self.create_roles(roles)
            roles.each do |role|
                Rbacan::Role.create(name: role)
            end
        end

        def self.create_permissions(permissions)
            permissions.each do |permission|
                Rbacan::Permission.create(name: permission)
            end
        end

        def self.assign_permissions_to_role(role_name, permissions)
            chosen_role = Rbacan::Role.find_by_name(role_name)
            permissions.each do |permission|
                given_permission = Rbacan::Permission.find_by_name(permission)
                Rbacan::RolePermission.create(role_id: chosen_role.id, permission_id: given_permission.id)
            end
        end
    end
end
