## Force absolute paths buildpack

This buildpack checks that not relative paths have snuck into the PATH or any path like env vars (checks for all that end in PATH like GEM_PATH). The intention of this buildpack is that you could use it in a test suite for buildpacks.

This repo has a very simple script in `lib/check_script.rb` that when executed loops through each PATH-like env var and raises an error if one of them has a relative path.
The script is executed at build time to catch any bad paths in `export` scripts. It also adds (or modifies) a release phase incantation to run at release time so it will check paths in a runtime like environment.

For example:

```
$ git push heroku master
Enumerating objects: 1, done.
Counting objects: 100% (1/1), done.
Writing objects: 100% (1/1), 185 bytes | 185.00 KiB/s, done.
Total 1 (delta 0), reused 0 (delta 0)
remote: Compressing source files... done.
remote: Building source:
remote:
remote: -----> I check that all paths are absolute app detected
remote: -----> Checking for absolute values in PATHs
remote:        Everything looks good to me
remote: -----> Updating release script in procfile
remote: -----> Discovering process types
remote:        Procfile declares types -> release
remote:
remote: -----> Compressing...
remote:        Done: 667B
remote: -----> Launching...
remote:  !     Release command declared: this new release will not be available until the command succeeds.
remote:        Released v15
remote:        https://cryptic-gorge-80699.herokuapp.com/ deployed to Heroku
remote:
remote: Verifying deploy... done.
remote: Running release command...
remote:
remote: -----> Checking for absolute values in PATHs
remote: bin/check_paths:9:in `block in <main>': All paths must be absolute, ENV["GEM_PATH"] contains "blerg" with relative_path "blerg" (RuntimeError)
remote:   from bin/check_paths:6:in `each'
remote:   from bin/check_paths:6:in `<main>'
remote: Waiting for release.... failed.
To https://git.heroku.com/cryptic-gorge-80699.git
   6a83c41..5478677  master -> master
```

## Checks

- All paths are absolute
- The build directory doesn't leak into a path at runtime (if build and runtime dirs are different)
- All paths are directories and they exist
