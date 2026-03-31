# Copy the content of this file into your seeds.rb and uncomment what you need.

# Define the roles you want, e.g.:
#   roles = ["admin", "moderator", "viewer"]
roles = []
Rbacan::RolesAndPermissions.create_roles(roles)


# Define the permissions you want, e.g.:
#   permissions = ["edit_post", "delete_post", "publish_post"]
permissions = []
Rbacan::RolesAndPermissions.create_permissions(permissions)


# Assign permissions to a role. Repeat this block for each role you want to configure.
# Replace "admin" with the role name, and list the permissions it should have.
#
# role_permissions = ["edit_post", "delete_post", "publish_post"]
# Rbacan::RolesAndPermissions.assign_permissions_to_role("admin", role_permissions)
#
# To assign all permissions to a role:
# Rbacan::RolesAndPermissions.assign_permissions_to_role("admin", permissions)
