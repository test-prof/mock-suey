# frozen_string_literal: true

require_relative "lib/mock_suey/version"

Gem::Specification.new do |s|
  s.name = "mock-suey"
  s.version = MockSuey::VERSION
  s.authors = ["Vladimir Dementyev"]
  s.email = ["dementiev.vm@gmail.com"]
  s.homepage = "http://github.com/test-prof/mock-suey"
  s.summary = "Utilities to keep mocks in line with real objects"
  s.description = "Utilities to keep mocks in line with real objects"

  s.metadata = {
    "bug_tracker_uri" => "http://github.com/test-prof/mock-suey/issues",
    "changelog_uri" => "https://github.com/test-prof/mock-suey/blob/master/CHANGELOG.md",
    "documentation_uri" => "http://github.com/test-prof/mock-suey",
    "homepage_uri" => "http://github.com/test-prof/mock-suey",
    "source_code_uri" => "http://github.com/test-prof/mock-suey",
    "funding_uri" => "https://github.com/sponsors/test-prof"
  }

  s.license = "MIT"

  s.files = Dir.glob("lib/**/*") + Dir.glob("bin/**/*") + %w[README.md LICENSE.txt CHANGELOG.md]
  s.require_paths = ["lib"]
  s.required_ruby_version = ">= 2.7"

  s.add_development_dependency "bundler", ">= 1.15"
  s.add_development_dependency "rake", ">= 13.0"
  s.add_development_dependency "rspec", ">= 3.9"

  # When gem is installed from source, we add `ruby-next` as a dependency
  # to auto-transpile source files during the first load
  if ENV["RELEASING_GEM"].nil? && File.directory?(File.join(__dir__, ".git"))
    s.add_runtime_dependency "ruby-next", ">= 0.15.0"
  else
    s.add_dependency "ruby-next-core", ">= 0.15.0"
  end
end
