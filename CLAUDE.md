# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
bin/setup          # install dependencies
rake spec          # run all tests
bundle exec rspec spec/rbacan_spec.rb   # run a single spec file
bundle exec rake install   # install gem locally
bundle exec rake release   # tag, push commits/tags, push .gem to RubyGems
gem build rbacan.gemspec   # build .gem file manually
gem push rbacan-<version>.gem           # push to RubyGems manually
```

## Architecture

This is a Rails engine gem that provides Role-Based Access Control (RBAC).

**Data model** — four tables managed by the gem's migrations:
- `roles` / `permissions` — named entities
- `role_permissions` — join table linking roles to permissions
- `user_roles` — join table linking the host app's user model to roles

**Entry points:**
- `lib/rbacan.rb` — main module; holds `mattr_accessor` config accessors and a `configure` block. All class names and table names are configurable here (defaults to `User`, `Rbacan::Role`, etc.).
- `lib/rbacan/permittable.rb` — `ActiveSupport::Concern` included in the host app's user model via `include Rbacan::Permittable`. Adds `assign_role`, `remove_role`, and `can?` instance methods.
- `lib/rbacan/roles_and_permissions.rb` — utility module (`RolesAndPermissions`) used in seeds to bulk-create roles/permissions and assign permissions to roles.
- `lib/rbacan/engine.rb` — Rails engine that auto-loads `app/models`.

**Generator** (`rails generate rbacan:install`) copies four migration files, `db/copy_to_seeds.rb`, and `config/initializers/rbacan.rb` into the host app.

**Configuration** (host app's `config/initializers/rbacan.rb`):
```ruby
Rbacan.configure do |config|
  config.permittable_class = "User"  # change if your user model has a different name
end
```

## Releasing a new version

1. Bump `lib/rbacan/version.rb`
2. `gem build rbacan.gemspec`
3. `gem push rbacan-<version>.gem`

RubyGems push host is `https://rubygems.org`. GitHub repo: `https://github.com/hamdi777/RBACan`.

## Known state

The spec suite has a placeholder test (`expect(false).to eq(true)`) in `spec/rbacan_spec.rb` that intentionally fails — it was never replaced with real tests.
