# frozen_string_literal: true

require "logger"

require "ruby-next"

require "ruby-next/language/setup"
RubyNext::Language.setup_gem_load_path(transpile: true)

require "mock_suey/version"
require "mock_suey/logging"
require "mock_suey/core"
require "mock_suey/method_call"
require "mock_suey/type_checks"
require "mock_suey/tracer"
require "mock_suey/mock_contract"

require "mock_suey/rspec" if defined?(RSpec::Core)
