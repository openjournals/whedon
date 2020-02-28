# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'whedon/version'

Gem::Specification.new do |spec|
  spec.name          = "whedon"
  spec.version       = Whedon::VERSION
  spec.authors       = ["Arfon Smith"]
  spec.email         = ["arfon.smith@gmail.com"]
  spec.summary       = "A collection of command-line utilities to manage JOSS submissions."
  spec.homepage      = "https://github.com/openjournals/whedon"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "bibtex-ruby"
  spec.add_dependency "dotenv"
  spec.add_dependency "latex-decode"
  spec.add_dependency "github-linguist", "~> 5.3"
  spec.add_dependency "metamatter", "~> 0.2.0"
  spec.add_dependency "openjournals-nameable"
  spec.add_dependency "octokit", "~> 4.0"
  spec.add_dependency "rest-client", ">= 1.8"
  spec.add_dependency "redcarpet", "~> 3.3"
  spec.add_dependency "tilt"
  spec.add_dependency "thor", "~> 0.19"
  spec.add_dependency "unicode", "~> 0.4.4"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "pry", "~> 0.10"
  spec.add_development_dependency "rspec", "~> 3.3"
  spec.add_development_dependency "vcr", "~> 4.0"
  spec.add_development_dependency "webmock", "~> 3.5.1"
  spec.add_development_dependency "nokogiri", "= 1.10.8"
end
