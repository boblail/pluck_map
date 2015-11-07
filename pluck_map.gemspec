# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "pluck_map/version"

Gem::Specification.new do |spec|
  spec.name          = "pluck_map"
  spec.version       = PluckMapPresenter::VERSION
  spec.authors       = ["Bob Lail"]
  spec.email         = ["bob.lail@cph.org"]

  spec.summary       = "A DSL for presenting ActiveRecord::Relations without instantiating ActiveRecord models"
  spec.homepage      = "https://github.com/boblail/pluck_map"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
end
