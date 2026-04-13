Rbacan.configure do |config|
  # The name of your user model (default: "User")
  # config.permittable_class = "User"

  # Override AR model class names if you have custom models
  # config.role_class             = "Rbacan::Role"
  # config.permission_class       = "Rbacan::Permission"
  # config.user_role_class        = "Rbacan::UserRole"
  # config.role_permission_class  = "Rbacan::RolePermission"

  # Override table names if needed
  # config.role_table             = "roles"
  # config.permission_table       = "permissions"
  # config.user_role_table        = "user_roles"
  # config.role_permission_table  = "role_permissions"

  # Primary key type for generated migrations.
  # Set to :uuid if your app uses UUID primary keys.
  # When nil, auto-detects from your Rails generator config (primary_key_type).
  # config.primary_key_type = :uuid

  # Enable tenant scoping for roles and user_roles.
  # When true, adds tenant_id to the roles and user_roles tables,
  # allowing tenant-specific roles and role assignments.
  # Permissions always remain global regardless of this setting.
  # config.tenant_scoped = false

  # The name of your tenant model class (default: "Tenant").
  # Only used when tenant_scoped is true.
  # config.tenant_class = "Tenant"

  # Authorization failure handling:
  #   :raise    — raises Rbacan::NotAuthorized (default)
  #   :redirect — redirects to unauthorized_redirect_path
  #   lambda    — called with (controller, permission:, role:)
  #
  # config.unauthorized_handler = :raise
  # config.unauthorized_handler = :redirect
  # config.unauthorized_handler = ->(controller, permission:, role:) {
  #   controller.render plain: "Forbidden", status: :forbidden
  # }

  # Path to redirect to when unauthorized_handler is :redirect
  # config.unauthorized_redirect_path = "/"
end
