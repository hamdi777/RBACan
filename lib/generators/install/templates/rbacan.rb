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
