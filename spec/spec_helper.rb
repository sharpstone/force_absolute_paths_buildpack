require "bundler/setup"

require 'rspec/retry'

ENV["HATCHET_BUILDPACK_BASE"] = "https://github.com/sharpstone/force_absolute_paths_buildpack.git"
ENV["HATCHET_BUILDPACK_BRANCH"] = ENV["CIRCLE_BRANCH"] if ENV["CIRCLE_BRANCH"]

require 'hatchet'
require 'pathname'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"
  config.verbose_retry       = true # show retry status in spec process
  config.default_retry_count = 2 if ENV['IS_RUNNING_ON_CI'] # retry all tests that fail again

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

require 'parallel_tests/test/runtime_logger' if ENV['RECORD_RUNTIME']

def run!(cmd)
  out = `#{cmd}`
  raise "Error running #{cmd}, output: #{out}" unless $?.success?
  out
end

def spec_dir
  Pathname.new(__dir__)
end

def generate_fixture_app(compile_script:, name: )
  app_dir = spec_dir.join("fixtures/repos/generated/#{name}")
  bin_dir = app_dir.join("bin")
  bin_dir.mkpath

  bin_compile = bin_dir.join("compile")

  if bin_compile.file?  && bin_compile.read != compile_script # File already exists, make sure we're not accidentally over-writing
    puts "WARNING: You are writing over #{bin_compile} with different contents. Ensure each test is using a unique name:"
    puts
    puts "Existing contents: #{bin_compile.read.inspect}"
    puts "New contents:      #{compile_script.inspect}"
  end
  bin_compile.write(compile_script)

  bin_detect = bin_dir.join("detect")
  bin_detect.write(<<~EOM)
    #!/usr/bin/env bash

    echo "inline buildpack"

    exit 0
  EOM

  app_dir.join("Procfile").write("")

  FileUtils.chmod("+x", bin_compile)
  FileUtils.chmod("+x", bin_detect)

  app_dir
end
