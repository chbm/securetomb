# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "cloudvault"
  spec.version       = '1.0'
  spec.authors       = ["Carlos Morgado"]
  spec.email         = ["chbm@primatas.org"]
  spec.summary       = %q{Cloud backup utility}
  spec.description   = %q{Cloud backup utility}
  spec.homepage      = "http://domainforproject.com/"
  spec.license       = "MIT"

  spec.files         = ['lib/cloudvault.rb']
  spec.executables   = ['bin/cloudvault']
  spec.test_files    = ['tests/test_base.rb']
  spec.require_paths = ["lib"]
end
