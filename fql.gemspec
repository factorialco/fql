require_relative "lib/fql/version"

Gem::Specification.new do |spec|
  spec.name = "fql"
  spec.version = FQL::VERSION
  spec.authors = ["Txus Bach"]
  spec.email = ["txus@factorial.co"]

  spec.summary = "Factorial Query Language"
  spec.homepage = "https://github.com/factorialco/fql"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata = {
    "bug_tracker_uri" => "https://github.com/factorialco/fql/issues",
    "changelog_uri" => "https://github.com/factorialco/fql/releases",
    "source_code_uri" => "https://github.com/factorialco/fql",
    "homepage_uri" => spec.homepage,
    "rubygems_mfa_required" => "true"
  }

  spec.add_runtime_dependency "activerecord", ">= 6", "< 8"
  spec.add_runtime_dependency "i18n", "~> 1.8"
  spec.add_runtime_dependency "sorbet-rails", "~> 0.7.3"
  spec.add_runtime_dependency "sorbet-runtime", "~> 0.5"
  spec.add_runtime_dependency "zeitwerk", "~> 2.4"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.glob(%w[LICENSE.txt README.md {exe,lib}/**/*]).reject { |f| File.directory?(f) }
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
