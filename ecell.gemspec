# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.authors       = ["Donovan Keme"]
  gem.email         = ["code@extremist.digital"]
  gem.description   = "Distributed Concurrent Objects, Evolved"
  gem.summary       = "Distributed Concurrent Objects, Evolved"
  gem.homepage      = "https://github.com/celluloid/ecell"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "timers"
  gem.require_paths = ["lib"]
  gem.version       = '0.0.0.0'
  gem.licenses      = ['MIT']

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec', '~> 3.0.0'

  gem.add_runtime_dependency 'celluloid', '~> 0.17'
  gem.add_runtime_dependency 'celluloid-zmq', '~> 0.17'
end
