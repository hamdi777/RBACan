module Rbacan
  class Role < ApplicationRecord
    self.table_name = Rbacan.role_table

    validates :name, presence: true
    validates :name, uniqueness: true, unless: -> { Rbacan.tenant_scoped && tenant_id.present? }
    validates :name, uniqueness: { scope: :tenant_id }, if: -> { Rbacan.tenant_scoped && tenant_id.present? }

    has_many :role_permissions, class_name: Rbacan.role_permission_class, dependent: :destroy
    has_many :permissions, class_name: Rbacan.permission_class, through: :role_permissions

    has_many :user_roles, class_name: Rbacan.user_role_class, dependent: :destroy
    has_many :users, class_name: Rbacan.permittable_class, through: :user_roles

    # Tenant association — only meaningful when tenant_scoped is enabled.
    # The column must exist in the database; it is added by the migration
    # when tenant_scoped is true.
    belongs_to :tenant, class_name: Rbacan.tenant_class, optional: true if Rbacan.tenant_scoped

    # Global roles have no tenant (tenant_id IS NULL).
    scope :global, -> { where(tenant_id: nil) }

    # Returns roles available for a specific tenant: its own roles plus global roles.
    scope :for_tenant, ->(tenant_id) { where(tenant_id: [tenant_id, nil]) }
  end
end
