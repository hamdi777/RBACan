module Rbacan
    class RolePermission < ApplicationRecord
        self.table_name = Rbacan.role_permission_table
        belongs_to :role, class_name: Rbacan.role_class
        belongs_to :permission, class_name: Rbacan.permission_class
    end
end
