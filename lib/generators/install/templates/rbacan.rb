Rbacan.configure do |config|
  # Hardened host-owned mode is the default. The generated 0.4-style schema remains
  # inactive until the host consciously opts into its destructive/unscoped APIs:
  # config.legacy_mode = true

  # Name of your user model (default: "User")
  # config.permittable_class = "User"

  # Override ActiveRecord model class names if you use custom models
  # config.role_class = "Rbacan::Role"
  # config.permission_class = "Rbacan::Permission"
  # config.user_role_class = "Rbacan::UserRole"
  # config.role_permission_class = "Rbacan::RolePermission"

  # Host role/permission lookup columns (default: :name)
  # config.role_key = :code
  # config.permission_key = :code

  # Override table names if needed
  # config.role_table = "roles"
  # config.permission_table = "permissions"
  # config.user_role_table = "user_roles"
  # config.role_permission_table = "role_permissions"

  # Primary key type for migrations.
  # Set :uuid if your app uses UUID primary keys.
  # When nil, auto-detects Rails generator config (primary_key_type).
  # config.primary_key_type = :uuid

  # Enable tenant scoping for roles and user_roles.
  # When true, adds tenant_id to roles and user_roles.
  # Permissions remain global regardless of this setting.
  # config.tenant_scoped = false

  # Name of your tenant model class (default: "Tenant").
  # Only used when tenant_scoped is true.
  # config.tenant_class = "Tenant"

  # Authorization failure handling:
  #   :raise    — raises Rbacan::NotAuthorized (default)
  #   :redirect — redirects to unauthorized_redirect_path
  #   lambda    — called with (controller, permission:, role:)
  # config.unauthorized_handler = :raise
  # config.unauthorized_redirect_path = "/"
end
