#!/usr/bin/env ruby

fail unless ARGV.length > 0
piece_id = ARGV[0].downcase

require 'bundler/setup'
Bundler.setup
require 'celluloid/current'
require 'ecell/constants'
require 'ecell/runner'

Celluloid.shutdown_timeout = ECell::Constants::INTERVALS[:max_graceful]
module Celluloid
  class << self
    @shutdown_registered = true #de We will kill it ourselves.
  end
end

runner = ECell::Runner.new

Signal.trap('INT') { runner.shutdown }


require_relative 'demo_mesh_configuration'
sketch = case piece_id
when 'monitor'
  require 'ecell/base/sketches/monitor'
  ECell::Base::Sketches::Monitor
when 'reel_static'
  require_relative 'reel_static'
  ReelStatic
end
log_dir = File.expand_path("../logs", __FILE__)
configuration = {
  piece_id: piece_id.to_sym,
  bindings: DEMO_MESH_BINDINGS,
  log_dir: log_dir
}
configuration.merge!(DEMO_MESH_HIERARCHY[piece_id.to_sym])
configuration.merge!(sketch)

runner.run! configuration

