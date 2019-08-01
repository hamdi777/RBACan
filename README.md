# Rbacan

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/rbacan`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rbacan'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rbacan

## Usage

run rails generate rbacan:install

- create your roles and permissions in your seed with these helpers 

    for roles:

    create_roles(roles_array)

    for permissions:

    create_permissions(permissions_array)

- then assign permissions to each role with in your seed also with this helper

    assign_permissions_to_role(role_name, permissions_array)

- last thing is going to be assigning roles to users u can do this by

    user = current_user
    user.assign_role(role_name)


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/hamdi777/rbacan. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Rbacan project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/rbacan/blob/master/CODE_OF_CONDUCT.md).
