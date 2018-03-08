require "bundler/gem_tasks"
require 'rspec/core/rake_task'

require 'dotenv'
Dotenv.load(".env.test")

require_relative './lib/whedon'

desc "Run specs"
RSpec::Core::RakeTask.new do |t|
  t.pattern = 'spec/**/*_spec.rb'
  t.rspec_opts = ["--order", "rand", "--color"]
end
