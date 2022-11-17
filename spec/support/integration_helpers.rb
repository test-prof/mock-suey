# frozen_string_literal: true

require "open3"

module IntegrationHelpers
  RUBY_RUNNER = if defined?(JRUBY_VERSION)
    # See https://github.com/jruby/jruby/wiki/Improving-startup-time#bundle-exec
    "jruby -G"
  else
    "bundle exec ruby"
  end

  RSPEC_STUB = File.join(__dir__, "../../bin/rspec")

  def run_rspec(path, chdir: nil, success: true, env: {}, options: "")
    command = "#{RUBY_RUNNER} #{RSPEC_STUB} #{options} #{path}_fixture.rb"
    output, err, status = Open3.capture3(
      env,
      command,
      chdir: chdir || File.expand_path("../../fixtures/rspec", __FILE__)
    )

    if ENV["DEBUG"] == "1"
      puts "\n\nCOMMAND:\n#{command}\n\nOUTPUT:\n#{output}\nERROR:\n#{err}\n"
    end

    warn output if output.match?(/warning:/i)
    [status, output]
  end

  def run_minitest(path, chdir: nil, success: true, env: {})
    command = "#{RUBY_RUNNER} #{path}_fixture.rb #{env["TESTOPTS"]}"

    output, err, status = Open3.capture3(
      env,
      command,
      chdir: chdir || File.expand_path("../../fixtures/minitest", __FILE__)
    )

    if ENV["DEBUG"] == "1"
      puts "\n\nCOMMAND:\n#{command}\n\nOUTPUT:\n#{output}\nERROR:\n#{err}\n"
    end

    warn output if output.match?(/warning:/i)
    [status, output]
  end
end
