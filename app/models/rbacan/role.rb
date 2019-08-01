module Rbacan
    class Role < ApplicationRecord
        self.table_name = Rbacan.role_table

        validates :name, presence: true, uniqueness: true
        
        has_many :role_permissions, class_name: Rbacan.role_permission_class, dependent: :destroy
        has_many :permissions, class_name: Rbacan.permission_class, through: :role_permissions

        has_many :user_roles, class_name: Rbacan.user_role_class, dependent: :destroy
        has_many :users, through: :user_roles
    end
end
