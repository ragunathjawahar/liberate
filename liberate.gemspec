# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'liberate/version'

Gem::Specification.new do |spec|
  spec.name          = "liberate"
  spec.version       = Liberate::VERSION
  spec.date          = "2016-07-27"
  spec.summary       = Liberate::NAME
  spec.description   = "A gem that liberates your Android devices from USB cables during development."
  spec.authors       = ["Ragunath Jawahar"]
  spec.email         = "rj@mobsandgeeks.com"
  spec.homepage      = "https://github.com/ragunathjawahar/liberate"
  spec.license       = "Apache-2.0"

  spec.files         = ["lib/liberate.rb"]
  spec.bindir        = "bin"
  spec.executables   << "liberate"
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.0.0'

  # Dependencies
  spec.add_dependency 'colorize', '~> 0.8.1'
end
