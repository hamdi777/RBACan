#Copy the content of this file into your seeds.rb and comment what you don't need


# define the roles you are going to use example: roles = ["support", "carrier", "mid lane :D", "bot lane :p"]
roles = []
# create roles
Rbacan::RolesAndPermissions.create_roles(roles)


# define the permissions you are going to use example: permissions = ["fire", "invoke", "fly"]
permissions = []
# create permissions
Rbacan::RolesAndPermissions.create_permissions(permissions)


# now assign some permissions to each role 
# to do that you need to define an array of the permissions you want to assign example: 
# role_permissions = ["fly", "fire"]
role_permissions = []
Rbacan::RolesAndPermissions.assign_permissions_to_role(role_name, role_permissions)
# example Rbacan::RolesAndPermissions.assign_permissions_to_role("mid lane :D", role_permissions)
# you can even define an array of many roles and then do :
# roles.each do |role|
#   role_name = role.name
#   Rbacan::RolesAndPermissions.assign_permissions_to_role(role_name, role_permissions)
# end