
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "rbacan/version"

Gem::Specification.new do |spec|
  spec.name          = "rbacan"
  spec.version       = Rbacan::VERSION
  spec.authors       = ["hamdi"]
  spec.email         = ["hamdi_amiche@outlook.fr"]

  spec.summary       = %q{a gem to give permission access to users looknig back to their roles}
  spec.description   = %q{RBACan is a Role-based access control tool to control user access to the functionnalities of your application}
  spec.homepage      = "https://github.com/hamdi777/RBACan"
  spec.licenses      = ["MIT"]

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://rubygems.org/profiles/hamdi777"

    spec.metadata["homepage_uri"] = spec.homepage
    spec.metadata["source_code_uri"] = "https://rubygems.org/profiles/hamdi777"
    spec.metadata["changelog_uri"] = "https://rubygems.org/profiles/hamdi777/CHANGELOG.md"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'rails', '>= 4.2'
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency 'generator_spec', '~> 0.9.4'
  spec.add_development_dependency 'railties', '~> 5.2', '>= 5.2.3'
end
