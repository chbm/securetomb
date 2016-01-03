# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "securetomb"
  spec.version       = '1.0'
  spec.authors       = ["Carlos Morgado"]
  spec.email         = ["chbm@primatas.org"]
  spec.summary       = %q{Cloud backup utility}
  spec.description   = %q{Cloud backup utility}
  spec.homepage      = "http://domainforproject.com/"
  spec.license       = "MIT"

  spec.files         = ['lib/cloudvault.rb']
  spec.executables   = ['securetomb']
  spec.test_files    = ['tests/test_base.rb']
  spec.require_paths = ["lib"]
	
	spec.add_runtime_dependency "sqlite3"
	spec.add_runtime_dependency "tempfile"
	spec.add_runtime_dependency "clamp"
	spec.add_runtime_dependency "rest-client"
	spec.add_runtime_dependency "filter_io"
end
