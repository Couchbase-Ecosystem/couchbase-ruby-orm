# Release Process

  This document describes the process for releasing a new version of couchbase-orm.

  ## Prerequisites

  - Write access to the repository
  - RubyGems account with push permissions for the gem
  - Clean local master branch

  ## Release Steps

  ### 1. Update Version

  Edit `lib/couchbase-orm/version.rb` with the new version number:

  ```ruby
  # frozen_string_literal: true, encoding: ASCII-8BIT

  module CouchbaseOrm
    VERSION = 'X.Y.Z'
  end

  Commit the change:

  git add lib/couchbase-orm/version.rb
  git commit -m "Bump version to X.Y.Z"
  git push origin master

  2. Create Git Tag

  Tag the release on master:

  git tag X.Y.Z
  git push origin X.Y.Z

  3. Verify Clean State

  Ensure your local master branch is clean and up-to-date:

  git checkout master
  git pull
  git status  # Should show "nothing to commit, working tree clean"

  4. Build the Gem

  Build the gem locally:

  gem build couchbase-orm.gemspec

  This will create a file like couchbase-orm-X.Y.Z.gem.

  5. Push to RubyGems

  Push the built gem to RubyGems (you'll need your OTP code):

  gem push couchbase-orm-X.Y.Z.gem --otp YOUR_OTP_CODE

  Note: Replace YOUR_OTP_CODE with your actual one-time password from your authenticator app.

  6. Verify Release

  Check that the new version appears on the gem page:

  https://rubygems.org/gems/couchbase-orm

  Post-Release

  - Announce the release if applicable (changelog, team communication, etc.)
  - Update any documentation that references the version number

  Version Numbering

  This project follows https://semver.org/:

  - MAJOR version for incompatible API changes
  - MINOR version for backwards-compatible functionality additions
  - PATCH version for backwards-compatible bug fixes


