module Rbacan
    class UserRole < ApplicationRecord
        self.table_name = Rbacan.user_role_table
        belongs_to :role, class_name: Rbacan.role_class
        belongs_to :user, class_name: Rbacan.permittable_class
    end
end
