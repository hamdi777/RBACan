require 'rbacan/version'
require 'rbacan/not_authorized'
require 'rbacan/host_authorization'
require 'rbacan/authorizable'
require 'rbacan/permittable'
require 'rbacan/engine'
require 'rbacan/roles_and_permissions'
require 'rbacan/authorization'
require 'rbacan/view_helpers'
require 'rbacan/route_constraint'

module Rbacan
  mattr_accessor :authorization_adapter
  @@authorization_adapter = nil

  mattr_accessor :assignment_adapter
  @@assignment_adapter = nil

  # Legacy Active Record mutation/query APIs are opt-in in the hardened API.
  mattr_accessor :legacy_mode
  @@legacy_mode = false

  mattr_accessor :permittable_class
  @@permittable_class = 'User'

  mattr_accessor :role_class
  mattr_accessor :role_table
  mattr_accessor :role_key
  @@role_class = 'Rbacan::Role'
  @@role_table = 'roles'
  @@role_key = :name

  mattr_accessor :user_role_class
  mattr_accessor :user_role_table
  @@user_role_class = 'Rbacan::UserRole'
  @@user_role_table = 'user_roles'

  mattr_accessor :permission_class
  mattr_accessor :permission_table
  mattr_accessor :permission_key
  @@permission_class = 'Rbacan::Permission'
  @@permission_table = 'permissions'
  @@permission_key = :name

  mattr_accessor :role_permission_class
  mattr_accessor :role_permission_table
  @@role_permission_class = 'Rbacan::RolePermission'
  @@role_permission_table = 'role_permissions'

  # :raise (default), :redirect, or any callable (lambda/proc).
  mattr_accessor :unauthorized_handler
  @@unauthorized_handler = :raise

  # Redirect path used when unauthorized_handler is :redirect.
  mattr_accessor :unauthorized_redirect_path
  @@unauthorized_redirect_path = '/'

  # Primary key type for generated migrations.
  # nil = auto-detect from Rails generator config (primary_key_type).
  # Set to :uuid for UUID primary keys, or :bigint for standard integer keys.
  mattr_accessor :primary_key_type
  @@primary_key_type = nil

  # When true, adds tenant_id to roles and user_roles tables,
  # enabling tenant-scoped roles and role assignments.
  # Permissions remain global (no tenant_id) regardless of this setting.
  mattr_accessor :tenant_scoped
  @@tenant_scoped = false

  # The name of your tenant model class (default: "Tenant").
  # Only used when tenant_scoped is true.
  mattr_accessor :tenant_class
  @@tenant_class = 'Tenant'

  # Resolves the effective primary key type.
  # Checks the explicit config first, then falls back to the Rails generator config.
  def self.resolve_primary_key_type
    return primary_key_type if primary_key_type.present?

    Rails.configuration.generators.options.dig(:active_record, :primary_key_type)
  rescue StandardError
    nil
  end

  def self.create_role(role_name)
    @@role_class.constantize.create(@@role_key => role_name.to_s)
  end

  def self.create_permission(permission_name)
    @@permission_class.constantize.create(@@permission_key => permission_name.to_s)
  end

  def self.assign_permission_to_role(role_name, permission_name)
    chosen_role = @@role_class.constantize.find_by(@@role_key => role_name.to_s)
    given_permission = @@permission_class.constantize.find_by(@@permission_key => permission_name.to_s)
    @@role_permission_class.constantize.create(
      role_id: chosen_role.id,
      permission_id: given_permission.id
    )
  end

  def self.configure
    yield self
  end

  class Error < StandardError; end
end
