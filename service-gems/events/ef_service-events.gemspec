# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.name          = "ef_service-events"
  gem.version       = '0.3.0'
  gem.authors       = ["Ross Attrill", "Donovan Keme, //de"]
  gem.email         = ["ross.attrill@energyone.com.au", "de@emotive.limited"]
  gem.description   = "Ef::Service::Events extraction."
  gem.summary       = "Ef::Service::Events extraction."
  gem.homepage      = "http://github.com/energyone/ef_service-events"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.require_paths = ["lib"]

end
