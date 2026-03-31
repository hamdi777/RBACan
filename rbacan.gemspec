
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "rbacan/version"

Gem::Specification.new do |spec|
  spec.name          = "rbacan"
  spec.version       = Rbacan::VERSION
  spec.authors       = ["hamdi"]
  spec.email         = ["hamdi_amiche@outlook.fr"]

  spec.summary       = %q{A gem to give permission access to users based on their roles}
  spec.description   = %q{RBACan is a Role-Based Access Control tool to control user access to the functionalities of your application}
  spec.homepage      = "https://github.com/hamdi777/RBACan"
  spec.licenses      = ["MIT"]

  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://rubygems.org"
    spec.metadata["homepage_uri"]      = spec.homepage
    spec.metadata["source_code_uri"]   = "https://github.com/hamdi777/RBACan"
    spec.metadata["changelog_uri"]     = "https://github.com/hamdi777/RBACan/blob/master/CHANGELOG.md"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'rails', '>= 5.2'

  spec.add_development_dependency "bundler",      ">= 2.0"
  spec.add_development_dependency "rake",         "~> 13.0"
  spec.add_development_dependency "rspec",        "~> 3.0"
  spec.add_development_dependency "generator_spec", "~> 0.9.4"
  spec.add_development_dependency "railties",     ">= 5.2"
  spec.add_development_dependency "activerecord", ">= 5.2"
  spec.add_development_dependency "sqlite3",      ">= 1.4"
end
