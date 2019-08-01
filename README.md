# Rbacan

a Role-based access control tool to manipulate user access to the functionnalities of your application

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

copy the content in the generated file db/copy_to_seed.rb in your seeds.rb file
you have there all the tools you need to create you roles and permissions

if you want to assign a role to a user it is simple you just have to do so:

    user = current_user

    user.assign_role(role_name)

to remove a role from user do this:

    user.remove_role(role_name)

now when you want to test if a user have access to a functionnality use this:

    user.can?(permission_name)

add this line to your user model:

    include Rbacan::Permittable

run:
    bin/rails db:migrate

enjoy :D
## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/hamdi777/rbacan. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Rbacan project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/rbacan/blob/master/CODE_OF_CONDUCT.md).
