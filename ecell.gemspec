# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.name          = "ecell"
  gem.version       = '0.0.0.1'
  gem.authors       = ["Donovan Keme, //de", "benzrf"]
  gem.email         = ["code@extremist.digital"]
  gem.description   = "ECell: Distributed strategic actors."
  gem.summary       = "ECell is a framework built on Celluloid and ØMQ for building concurrent, networked, service-based systems."
  gem.homepage      = "https://github.com/celluloid/ecell"

  gem.files         = Dir.glob("{bin,lib,public}/**/*") + %w(README.md ZMQ.md CHANGELOG)
  gem.test_files    = Dir.glob("spec/**/*")
  gem.require_path  = 'lib'

  gem.add_runtime_dependency 'msgpack'

  gem.add_runtime_dependency 'celluloid'
  gem.add_runtime_dependency 'celluloid-io'
  gem.add_runtime_dependency 'celluloid-zmq'

  gem.add_runtime_dependency 'celluloid-task-pooledfiber'

  # gem.add_runtime_dependency 'esto'
  # gem.add_runtime_dependency 'refrescar'

  gem.add_runtime_dependency 'pry'
  gem.add_runtime_dependency 'colorize'
  gem.add_runtime_dependency 'sinatra'
  gem.add_runtime_dependency 'puma'
  gem.add_runtime_dependency 'websocket_parser'

  gem.add_development_dependency 'rspec'
end

