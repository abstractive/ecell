# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.name          = "ecell"
  gem.version       = '0.0.0.1'
  gem.authors       = ["Donovan Keme, //de"]
  gem.email         = ["code@extremist.digital"]
  gem.description   = "ECell: Distributed strategic actors."
  gem.summary       = "ECell: Distributed strategic actors."
  gem.homepage      = "http://github.com/celluloid/ecell"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.require_paths = ["lib"]

end
