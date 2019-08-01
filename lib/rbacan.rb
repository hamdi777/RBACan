require "rbacan/version"
require "rbacan/permittable"
require 'rbacan/engine'
require "rbacan/roles_and_permissions"

module Rbacan
  mattr_accessor :permittable_class
  # mattr_accessor :permittable_table
  @@permittable_class = 'User'
  # @@permittable_table = @@permittable_class.tableize

  mattr_accessor :role_class
  mattr_accessor :role_table
  @@role_class = 'Rbacan::Role'
  @@role_table = 'roles'

  mattr_accessor :user_role_class
  mattr_accessor :user_role_table
  @@user_role_class = 'Rbacan::UserRole'
  @@user_role_table = 'user_roles'

  mattr_accessor :permission_class
  mattr_accessor :permission_table
  @@permission_class = 'Rbacan::Permission'
  @@permission_table = 'permissions'

  mattr_accessor :role_permission_class
  mattr_accessor :role_permission_table
  @@role_permission_class = 'Rbacan::RolePermission'
  @@role_permission_table = 'role_permissions'

  def create_role(role_name)
    @@role_class.create(name: role_name)
  end

  def create_permission(permission_name)
    @@permission_class.create(name: permission_name)
  end

  def assign_permission_to_role(role_name, permission_name)
    chosen_role = @@role_class.find_by_name(role_name)
    given_permission = @@permission_class.find_by_name(permission_name)
    @@role_permission_class.create(role_id: chosen_role.id, perm_id: given_permission.id)
  end

  def assign_role_to_user(role_name)
      assigned_role = Role.find_by_name(role_name)
      @@user_role_class.create(user_id: self.id, role_id: assigned_role.id)
  end

  def remove_user_role(role_name)
      removed_role = Role.find_by_name(role_name)
      @@user_role_class.where(user_id: self.id, role_id: removed_role.id).destroy_all
  end

  class Error < StandardError; end
  # Your code goes here...
end
