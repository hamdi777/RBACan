# RBACan

Role-Based Access Control for Rails. Assign roles to users, attach permissions to roles, and enforce access at the controller, view, and route level.

## Table of Contents

- [Installation](#installation)
- [Setup](#setup)
- [Configuration](#configuration)
- [Defining Roles and Permissions](#defining-roles-and-permissions)
- [Role Management](#role-management)
- [Checking Permissions](#checking-permissions)
- [Querying Users by Role or Permission](#querying-users-by-role-or-permission)
- [Controller Authorization](#controller-authorization)
- [View Helpers](#view-helpers)
- [Route Constraints](#route-constraints)
- [Development](#development)
- [Contributing](#contributing)
- [License](#license)

---

## Installation

Add to your Gemfile:

```ruby
gem 'rbacan'
```

Then run:

```bash
bundle install
```

---

## Setup

RBACan 0.5 has two explicit integration modes:

- **Host-owned mode (recommended):** the application owns schema, tenancy, scopes, assignment history,
  and record policies. Include `Rbacan::Authorizable` and configure adapters. Do not run the generator.
- **Legacy generated-schema mode:** preserves the 0.4 Active Record API only after conscious
  `config.legacy_mode = true` opt-in. Its removal methods delete join rows and are unsuitable for
  immutable assignment-history requirements.

### Host-owned mode

```ruby
class User < ApplicationRecord
  include Rbacan::Authorizable
end

Rbacan.configure do |config|
  config.role_class = 'Role'
  config.role_key = :code
  config.permission_class = 'Permission'
  config.permission_key = :code
  config.authorization_adapter = MyAuthorizationAdapter.new
  config.assignment_adapter = MyAssignmentAdapter.new
end
```

Every check receives an explicit immutable value context. Pass stable identifiers or JSON-like
references, not live Active Record objects:

```ruby
context = Rbacan::AuthorizationContext.new(
  tenant: current_tenant.id,
  property: current_property.id,
  vertical: current_property.property_type.to_s,
  subject: { type: reservation.class.name, id: reservation.id },
  at: Time.current
)

current_user.can?(:hotel_reservations_read, context: context)
```

The tenant identifier is required and cannot be nil, boolean, or empty. Tenant, property, vertical,
subject, metadata, and timestamp values are copied
and frozen when the context is created. Context identifiers must come from records already loaded
through the host application's authenticated scope; the authorization adapter resolves and validates
their relationships under the host's tenancy/RLS rules. The request's `user` remains the live host
principal object.

Adapters receive one request object. Authorization adapters respond to `allowed?(request)` or `call`;
assignment adapters respond to `assign(request)` and `revoke(request)`. RBACan never prescribes deletion
or caching in host-owned mode. Optional context metadata is deeply copied and frozen and accepts only
hashes, arrays, strings, finite integers/floats, booleans, nil, and symbols.

### Legacy generated-schema mode

**1. Run the generator**

```bash
rails generate rbacan:install
```

This copies four migrations, a seed helper file, and an initializer into your app.

**2. Migrate**

```bash
rails db:migrate
```

**3. Include the concern in your user model**

```ruby
class User < ApplicationRecord
  include Rbacan::Permittable
end
```

**4. Define your roles and permissions in `db/seeds.rb`**

Open `db/copy_to_seeds.rb` (created by the generator) and copy its contents into your `db/seeds.rb`. Fill in your roles and permissions, then run:

```bash
rails db:seed
```

---

## Configuration

The generator creates `config/initializers/rbacan.rb`. Generated-schema applications must explicitly
enable legacy mode; the remaining defaults then work for a standard Devise setup.

```ruby
Rbacan.configure do |config|
  # Conscious opt-in required for the destructive/unscoped 0.4 API while migrating.
  config.legacy_mode = true

  # Your user model name (default: "User")
  config.permittable_class = "User"

  # Host key columns default to :name.
  # config.role_key = :code
  # config.permission_key = :code

  # Override model class names if you have custom implementations
  # config.role_class             = "Rbacan::Role"
  # config.permission_class       = "Rbacan::Permission"
  # config.user_role_class        = "Rbacan::UserRole"
  # config.role_permission_class  = "Rbacan::RolePermission"

  # Override table names if needed
  # config.role_table             = "roles"
  # config.permission_table       = "permissions"
  # config.user_role_table        = "user_roles"
  # config.role_permission_table  = "role_permissions"

  # How to handle unauthorized access (see Controller Authorization)
  # config.unauthorized_handler = :raise       # default — raises Rbacan::NotAuthorized
  # config.unauthorized_handler = :redirect    # redirects to unauthorized_redirect_path
  # config.unauthorized_handler = ->(controller, permission:, role:) {
  #   controller.render plain: "Forbidden", status: :forbidden
  # }

  # Redirect path used when unauthorized_handler is :redirect (default: "/")
  # config.unauthorized_redirect_path = "/login"
end
```

---

## Defining Roles and Permissions

In legacy mode, use the `Rbacan::RolesAndPermissions` module in your seeds. All methods are idempotent — safe to run multiple times. Hardened mode rejects these unscoped helpers; host-owned applications must seed their own scoped authorization records.

```ruby
# db/seeds.rb

roles       = ["admin", "moderator", "viewer"]
permissions = ["edit_post", "delete_post", "publish_post", "view_dashboard"]

Rbacan::RolesAndPermissions.create_roles(roles)
Rbacan::RolesAndPermissions.create_permissions(permissions)

# Assign permissions to each role
Rbacan::RolesAndPermissions.assign_permissions_to_role("admin",     permissions)
Rbacan::RolesAndPermissions.assign_permissions_to_role("moderator", ["edit_post", "publish_post"])
Rbacan::RolesAndPermissions.assign_permissions_to_role("viewer",    ["view_dashboard"])
```

You can also create roles and permissions programmatically at runtime:

```ruby
Rbacan.create_role("editor")
Rbacan.create_permission("manage_comments")
Rbacan.assign_permission_to_role("editor", "manage_comments")
```

---

## Role Management

```ruby
user = User.find(1)

# Assign a role — idempotent, safe to call multiple times
user.assign_role("admin")
user.assign_role(:moderator)

# Remove a role
user.remove_role("moderator")
```

---

## Checking Permissions

### On a single permission

```ruby
user.can?("edit_post")   # => true or false
user.can?(:edit_post)    # symbols work too
```

### Checking all permissions at once

```ruby
# Returns true only if the user has every listed permission
user.can_all?(:edit_post, :delete_post, :publish_post)
```

### Checking roles

```ruby
# Does the user have this specific role?
user.has_role?(:admin)

# Does the user have at least one of these roles?
user.has_any_role?(:admin, :moderator)
```

---

## Querying Users by Role or Permission

Use these ActiveRecord scopes to query your user table.

```ruby
# All users with the admin role
User.with_role(:admin)

# All users who have a given permission (via any of their roles)
User.with_permission(:publish_post)

# Combine with other scopes
User.with_role(:moderator).where(active: true)
```

---

## Controller Authorization

Include `Rbacan::Authorization` in your `ApplicationController` (or any specific controller):

```ruby
class ApplicationController < ActionController::Base
  include Rbacan::Authorization
  helper_method :rbacan_authorization_context

  private

  def rbacan_authorization_context
    AuthorizationContextResolver.call(request: request, user: current_user, subject: @post)
  end
end
```

The host resolver must build the immutable identifier context only after authenticating the user and
loading tenant, property, and optional subject records through the authorized scope.
`AuthorizationContextResolver` is application-defined; RBACan does not infer these values.

Then use `authorize!` or `authorize_role!` as `before_action` callbacks:

```ruby
class PostsController < ApplicationController
  before_action -> { authorize!(:edit_post) },   only: [:edit, :update]
  before_action -> { authorize!(:delete_post) },  only: [:destroy]
  before_action -> { authorize_role!(:admin) },   only: [:admin_index]
end
```

Or call them directly inside an action:

```ruby
def destroy
  authorize!(:delete_post)
  @post.destroy
end
```

### Handling unauthorized access

The default behavior raises `Rbacan::NotAuthorized`. You can rescue it globally:

```ruby
# app/controllers/application_controller.rb
rescue_from Rbacan::NotAuthorized, with: :handle_unauthorized

private

def handle_unauthorized(exception)
  render plain: exception.message, status: :forbidden
end
```

Or configure a different handler in the initializer:

```ruby
# Redirect to a path instead of raising
config.unauthorized_handler      = :redirect
config.unauthorized_redirect_path = "/login"

# Or use a fully custom lambda
config.unauthorized_handler = ->(controller, permission:, role:) {
  controller.render json: { error: "Forbidden" }, status: :forbidden
}
```

---

## View Helpers

`Rbacan::ViewHelpers` is automatically included in all views. In host-owned mode the host must expose
`current_user` and `rbacan_authorization_context` to the view. Use `authorized?` to conditionally
render content:

```erb
<% authorized?(:delete_post) do %>
  <%= link_to "Delete", post_path(@post), data: { turbo_method: :delete } %>
<% end %>

<% authorized?(:publish_post) do %>
  <%= button_to "Publish", publish_post_path(@post) %>
<% end %>
```

You can also use `has_role?` directly in views through the host-owned concern:

```erb
<% if current_user.has_role?(:admin, context: rbacan_authorization_context) %>
  <%= link_to "Admin Panel", admin_root_path %>
<% end %>
```

---

## Route Constraints

Restrict access to entire route namespaces based on role or permission. Hardened mode requires explicit
request resolvers:

```ruby
resolve_user = ->(request) { CurrentSessionResolver.call(request) }
resolve_context = ->(request) { AuthorizationContextResolver.call(request) }

constraints Rbacan::RouteConstraint.new(
  role: :admin,
  user_resolver: resolve_user,
  context_resolver: resolve_context
) do
  namespace :admin do
    resources :users
    resources :roles
  end
end

constraints Rbacan::RouteConstraint.new(
  permission: :access_dashboard,
  user_resolver: resolve_user,
  context_resolver: resolve_context
) do
  get "/dashboard", to: "dashboard#index"
end
```

Without both resolvers hardened constraints fail closed. In explicitly enabled legacy mode only, the
constraint retains the 0.4 behavior of reading Warden or `session[:user_id]`.

---

## Development

```bash
bin/setup          # install dependencies
bundle exec rake spec                        # run all tests
bundle exec rspec spec/rbacan_spec.rb        # run a specific file
bundle exec rake install                     # install gem locally
```

To release a new version:

1. Bump the version in `lib/rbacan/version.rb`
2. `gem build rbacan.gemspec`
3. `gem push rbacan-<version>.gem`

---

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/hamdi777/RBACan.

---

## License

Available as open source under the [MIT License](https://opensource.org/licenses/MIT).
