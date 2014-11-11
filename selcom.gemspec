# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'selcom/version'

Gem::Specification.new do |spec|
  spec.name          = "selcom"
  spec.version       = Selcom::VERSION
  spec.authors       = ["Mawuli Adzoe"]
  spec.email         = ["mawuli.kofi.mawuli@gmail.com"]
  spec.summary       = %q{Ruby API wrapper for the Selcom XMLRPC API}
  spec.description   = %q{Use this gem so you don't have to interact with the Selcome XML RPC API directly.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'activesupport'
  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "nokogiri"



end
