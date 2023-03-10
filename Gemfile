# frozen_string_literal: true

source "https://rubygems.org"

gem "debug", platform: :mri
gem "rbs", "< 3.0"
gem "rspec"
gem 'sorbet', require: false
gem 'sorbet-runtime', require: false
gem 'tapioca', require: false

gemspec

eval_gemfile "gemfiles/rubocop.gemfile"

local_gemfile = "#{File.dirname(__FILE__)}/Gemfile.local"

if File.exist?(local_gemfile)
  eval(File.read(local_gemfile)) # rubocop:disable Security/Eval
end
