#! /usr/bin/env ruby
STDOUT.sync = true

puts "-----> Checking for absolute values in PATHs"

if ENV["FORCE_ABSOLUTE_PATHS_BUILDPACK_BUILD_DIR"]
  buildpack_build_dir = ENV["FORCE_ABSOLUTE_PATHS_BUILDPACK_BUILD_DIR"]

  # If the build dir and runtime dir are the same, we don't need to run the check
  buildpack_build_dir = nil if buildpack_build_dir == File.expand_path(".")
end

ENV.select {|k,v| k.end_with?("PATH") }.each do |env_key, env_value|
  path_parts = env_value.split(":")
  # Check relative paths
  if (relative_path = path_parts.detect {|path| !path.start_with?("/")})
    msg = %Q{All paths must be absolute, ENV["#{env_key}"] contains #{env_value.inspect} with relative_path #{relative_path.inspect}}
    raise msg
  end

  # Check for build tmp path leaking into runtime
  if buildpack_build_dir && (leaky_path = path_parts.detect {|path| path.start_with?(buildpack_build_dir) })
    msg = %Q{A build path leaked into runtime, ENV["#{env_key}"] contains #{env_value.inspect} with leaky path #{leaky_path.inspect}}
    raise msg
  end

  # Check directories exist
  if (not_a_directory = path_parts.detect {|path| !File.directory?(path) })
    msg = %Q{All paths should be directories, ENV["#{env_key}"] contains #{env_value.inspect} which is not a directory #{not_a_directory.inspect}}
    raise msg
  end
end

puts "       Everything looks good to me"
exit 0
