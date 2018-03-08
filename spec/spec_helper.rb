require "bundler/setup"
require "vcr"

VCR.configure do |config|
  config.cassette_library_dir = "fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.filter_sensitive_data("<GITHUB_TOKEN>") { ENV['GH_TOKEN'] }
end

require_relative "../lib/whedon"
