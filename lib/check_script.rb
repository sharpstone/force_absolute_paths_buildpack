#! /usr/bin/env ruby
STDOUT.sync = true

puts "-----> Checking for absolute values in PATHs"

if ENV["FORCE_ABSOLUTE_PATHS_BUILDPACK_BUILD_DIR"]
  buildpack_build_dir = ENV["FORCE_ABSOLUTE_PATHS_BUILDPACK_BUILD_DIR"]

  # If the build dir and runtime dir are the same, we don't need to run the check
  buildpack_build_dir = nil if buildpack_build_dir == File.expand_path(".")
end

ignore_paths = ENV.fetch("FORCE_ABSOLUTE_PATHS_BUILDPACK_IGNORE_PATHS", "").split(",").each_with_object({}) {|path, hash| hash[path.upcase] = true }

ENV.select {|k,v| k.end_with?("PATH") }.each do |env_key, env_value|
  if ignore_paths.key?(env_key)
    puts "Ignoring key #{env_key} due to FORCE_ABSOLUTE_PATHS_BUILDPACK_IGNORE_PATHS=#{ENV["FORCE_ABSOLUTE_PATHS_BUILDPACK_IGNORE_PATHS"]}"
    next
  end

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
end

puts "       Everything looks good to me"
exit 0
