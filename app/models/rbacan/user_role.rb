module Rbacan
  class UserRole < ApplicationRecord
    self.table_name = Rbacan.user_role_table

    belongs_to :role, class_name: Rbacan.role_class
    belongs_to :user, class_name: Rbacan.permittable_class

    # Tenant association — only meaningful when tenant_scoped is enabled.
    belongs_to :tenant, class_name: Rbacan.tenant_class, optional: true if Rbacan.tenant_scoped
  end
end
