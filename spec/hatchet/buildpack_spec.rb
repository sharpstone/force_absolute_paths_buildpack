require_relative "../spec_helper.rb"

RSpec.describe "This buildpack" do
  it "accepts absolute paths at build and runtime" do
    app_dir = generate_fixture_app(
      name: "works",
      compile_script: <<~EOM
        #!/usr/bin/env bash


        # Test export
        echo "PATH=/good/absolute/path:$PATH" >> export

        # Test .profile.d
        BUILD_DIR=$1
        mkdir -p $BUILD_DIR/.profile.d

        echo "PATH=/good/absolute/path:$PATH" >> $BUILD_DIR/.profile.d/my.sh
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

          echo "PATH=bad_export_path_because_im_relative:$PATH" >> export
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

          echo "PATH=bad_export_path_because_im_relative:$PATH" >> $BUILD_DIR/.profile.d/my.sh
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
end
