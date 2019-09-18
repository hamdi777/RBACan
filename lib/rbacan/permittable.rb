require 'active_support'

module Rbacan
    module Permittable
        extend ActiveSupport::Concern

        included do

            has_many :user_roles, class_name: Rbacan.user_role_class, dependent: :destroy
            has_many :roles, class_name: Rbacan.role_class, through: :user_roles

            def assign_role(role_name)
                assigned_role = Rbacan::Role.find_by_name(role_name)
                self.user_roles.find_or_create_by(role_id: assigned_role.id)
                self.save if self.persisted?
            end

            def remove_role(role_name)
                removed_role = Rbacan::Role.find_by_name(role_name)
                Rbacan::UserRole.where(user_id: self.id, role_id: removed_role.id).destroy_all
            end

            def can?(permission)
                @user_roles = self.roles
                user_permission = Rbacan::Permission.find_by_name(permission)
                if user_permission && @user_roles.joins(:role_permissions).where(role_permissions: {permission_id: user_permission.id}).count > 0
                    return true
                else
                    return false
                end
            end
        end
    end
end
