# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sequel-audit_by_day/version'

Gem::Specification.new do |gem|
  gem.name          = "sequel-audit_by_day"
  gem.version       = Sequel::AuditByDay::VERSION
  gem.authors       = ["Jonathan Tron", "Joseph Halter"]
  gem.email         = ["jonathan.tron@metrilio.com", "joseph.halter@metrilio.com"]
  gem.description   = "Audit by day for sequel_bitemporal"
  gem.summary       = gem.description
  gem.homepage      = "https://github.com/TalentBox/sequel-audit_by_day"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency "sequel_bitemporal", ">= 0.6.1"
end
