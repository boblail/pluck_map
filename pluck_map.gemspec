# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "pluck_map/version"

Gem::Specification.new do |spec|
  spec.name          = "pluck_map"
  spec.version       = PluckMapPresenter::VERSION
  spec.authors       = ["Bob Lail"]
  spec.email         = ["bob.lailfamily@gmail.com"]

  spec.summary       = "A DSL for presenting ActiveRecord::Relations without instantiating ActiveRecord models"
  spec.homepage      = "https://github.com/boblail/pluck_map"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord"

  spec.add_development_dependency "appraisal"
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest-reporters"
  spec.add_development_dependency "minitest-reporters-turn_reporter"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "mysql2"
  spec.add_development_dependency "pg"
  spec.add_development_dependency "database_cleaner"
  spec.add_development_dependency "shoulda-context"
  spec.add_development_dependency "rr"
  spec.add_development_dependency "pry"
end
