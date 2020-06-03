require_relative "../spec_helper.rb"

RSpec.describe "This buildpack" do
  it "accepts absolute paths at build and runtime" do
    app_dir = generate_fixture_app(
      name: "works",
      compile_script: <<~EOM
        #!/usr/bin/env bash


        # Test export
        echo "export PATH=#{Dir.pwd}:$PATH" >> export

        # Test .profile.d
        BUILD_DIR=$1
        mkdir -p $BUILD_DIR/.profile.d

        echo "export PATH=#{Dir.pwd}:$PATH" >> $BUILD_DIR/.profile.d/my.sh
      EOM
    )

    buildpacks = [
      "https://github.com/heroku/heroku-buildpack-inline",
      :default
    ]

    Hatchet::Runner.new(app_dir, buildpacks: buildpacks).deploy do |app|
      expect(app.output).to_not include("All paths must be absolute")
    end
  end

  describe "export detection" do
    it "errors on relative paths" do
      app_dir = generate_fixture_app(
        name: "export_fails_relative",
        compile_script: <<~EOM
          #!/usr/bin/env bash

          echo "export PATH=./bin:$PATH" >> export
        EOM
      )

      buildpacks = [
        "https://github.com/heroku/heroku-buildpack-inline",
        :default
      ]

      Hatchet::Runner.new(app_dir, buildpacks: buildpacks, allow_failure: true).deploy do |app|
        expect(app.output).to include("All paths must be absolute")
      end
    end
  end

  describe "profile.d detection" do
    it "errors on relative paths" do
      app_dir = generate_fixture_app(
        name: "export_fails_relative",
        compile_script: <<~EOM
          #!/usr/bin/env bash

          BUILD_DIR=$1
          mkdir -p $BUILD_DIR/.profile.d

          echo "export PATH=./bin:$PATH" >> $BUILD_DIR/.profile.d/my.sh
        EOM
      )

      buildpacks = [
        "https://github.com/heroku/heroku-buildpack-inline",
        :default
      ]

      Hatchet::Runner.new(app_dir, buildpacks: buildpacks, allow_failure: true).deploy do |app|
        expect(app.output).to include("All paths must be absolute")
      end
    end
  end

  describe "leaky build path detection" do
    it "errors on leaky paths" do
      app_dir = generate_fixture_app(
        name: "leaky_build_path",
        compile_script: <<~EOM
          #!/usr/bin/env bash

          BUILD_DIR=$1
          mkdir -p $BUILD_DIR/.profile.d

          echo "export PATH=$BUILD_DIR/bin:$PATH" >> $BUILD_DIR/.profile.d/my.sh
        EOM
      )

      buildpacks = [
        "https://github.com/heroku/heroku-buildpack-inline",
        :default
      ]

      Hatchet::Runner.new(app_dir, buildpacks: buildpacks, allow_failure: true).deploy do |app|
        expect(app.output).to include("A build path leaked into runtime")
      end
    end
  end

  describe "directory detection" do
    it "errors when a directory doesnt exist" do
      app_dir = generate_fixture_app(
        name: "directory_detection",
        compile_script: <<~EOM
          #!/usr/bin/env bash

          echo "export PATH=$BUILD_DIR/does_not_exist:$PATH" >> export
        EOM
      )

      buildpacks = [
        "https://github.com/heroku/heroku-buildpack-inline",
        :default
      ]

      Hatchet::Runner.new(app_dir, buildpacks: buildpacks, allow_failure: true).deploy do |app|
        puts app.output
        expect(app.output).to include("All paths should be directories")
      end
    end
  end
end
