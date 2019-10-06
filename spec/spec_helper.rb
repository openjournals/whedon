require "bundler/setup"
require "fileutils"
require "vcr"

VCR.configure do |config|
  config.cassette_library_dir = "fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.filter_sensitive_data("<GITHUB_TOKEN>") { ENV['GH_TOKEN'] }
end

require_relative "../lib/whedon"

# FIXME: This is kind of gross.
# Rugged needs there to be a Git repo present in the fixtures folder when
# running tests (spec/whedon_spec.rb#L11). Also, we're hard-coding the path
# to tmp/#{review_issue_id} so we need a fixture there.
Dir.mkdir('tmp') unless Dir.exist?('tmp')
FileUtils.rm_r('tmp/17') if Dir.exist?('tmp/17')
FileUtils.copy_entry('fixtures/paper', 'tmp/17')

# Any git repo will do (using the one from Whedon)
FileUtils.copy_entry('.git', 'tmp/17/.git')
