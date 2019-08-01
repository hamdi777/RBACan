module Rbacan
    class Permission < ApplicationRecord
        self.table_name = Rbacan.permission_table

        validates :name, presence: true, uniqueness: true

        has_many :role_permissions, class_name: Rbacan.role_permission_class, dependent: :destroy
        has_many :roles, class_name: Rbacan.role_class, through: :role_permissions
    end
end
