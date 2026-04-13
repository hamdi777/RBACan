# Changelog

All notable changes to this project will be documented in this file.

## [0.4.0] - 2026-04-13

### Added

- `primary_key_type` config option — auto-detects host app's primary key type (supports `:uuid` and `:bigint`)
- `tenant_scoped` config option — when `true`, adds `tenant_id` to `roles` and `user_roles` tables
- `tenant_class` config option — configurable tenant model class name (default: `"Tenant"`)
- `Rbacan.resolve_primary_key_type` — helper to resolve the effective PK type at runtime
- Tenant-aware methods on `Permittable`:
  - `roles_for_tenant(tenant_id)` — returns roles assigned in a specific tenant (+ global)
  - `has_role_in_tenant?(role_name, tenant_id)` — checks role in tenant context
  - `can_in_tenant?(permission_name, tenant_id)` — checks permission in tenant context
- `assign_role` now accepts optional `tenant_id:` keyword argument for tenant-scoped assignments
- `remove_role` now accepts optional `tenant_id:` keyword argument
- `Role` scopes: `.global` (where tenant_id IS NULL), `.for_tenant(tenant_id)` (tenant + global roles)
- `Role` model: conditional `belongs_to :tenant` when `tenant_scoped` is enabled
- `UserRole` model: conditional `belongs_to :tenant` when `tenant_scoped` is enabled
- Initializer template now documents all new configuration options
- Migration templates now use explicit `type:` on `t.references` for FK columns

### Fixed

- `t.bigint :user_id` was hardcoded in `create_user_roles` migration — now uses `t.references :user` with proper type detection matching the host app's PK type
- Migration templates now conditionally pass `id: :uuid` to `create_table` based on host app configuration
- `create_role_permissions` migration now specifies explicit `type:` on foreign key references

---

## [0.3.0] - 2026-03-31

### Added

- `Rbacan::Authorization` controller concern with `authorize!` and `authorize_role!` methods
- `Rbacan::NotAuthorized` exception class with readable messages (includes the missing permission or role name)
- `Rbacan::ViewHelpers` — `authorized?(permission) { }` block helper, auto-included into ActionView
- `Rbacan::RouteConstraint` — restrict route namespaces by role or permission via Warden/session
- `has_role?(role)` — check if a user has a specific role
- `has_any_role?(*roles)` — check if a user has at least one of the listed roles
- `can_all?(*permissions)` — check if a user has every listed permission (single query)
- `User.with_role(role)` scope — query all users with a given role
- `User.with_permission(permission)` scope — query all users who have a given permission via any role
- `unauthorized_handler` config option (`:raise`, `:redirect`, or a callable lambda/proc)
- `unauthorized_redirect_path` config option used when `unauthorized_handler` is `:redirect`
- DB-level unique indexes on `roles.name` and `permissions.name`
- Composite unique indexes on `role_permissions (role_id, permission_id)` and `user_roles (user_id, role_id)`
- Full RSpec test suite (29 examples) with in-memory SQLite setup and transaction rollback isolation

### Fixed

- `assign_role` was using `find_or_initialize_by` and never persisting the new `UserRole` record — fixed to `find_or_create_by`
- `Rbacan` module methods (`create_role`, `create_permission`, `assign_permission_to_role`) were calling `.create` on a String class name, raising `NoMethodError` — fixed with `.constantize`
- `remove_role` was hardcoding `user_id:` in a raw `where` clause — now uses the scoped `user_roles` association
- `can?` was issuing two queries (one to find the permission, one to check the join) — collapsed into a single `EXISTS` query
- `RolesAndPermissions` seed methods used `create` which would raise on re-runs — changed to `find_or_create_by`
- Seed file template referenced an undefined local variable `role_name` — fixed with commented examples
- Migration files were locked to `ActiveRecord::Migration[5.2]` — now use `current_version` dynamically

### Changed

- `rails >= 4.2` dependency bumped to `>= 5.2` (required for `Migration.current_version`)
- `rake ~> 10.0` dev dependency bumped to `~> 13.0` (Rake 10 is incompatible with Ruby 3+)
- Initializer template updated to document all available configuration options
- README fully rewritten to cover all features

---

## [0.1.4] - (initial release)

- Role and permission models with migrations
- `assign_role` / `remove_role` on user
- `can?(permission)` permission check
- `rails generate rbacan:install` generator
- `Rbacan::RolesAndPermissions` seed helpers
- Configurable `permittable_class`
