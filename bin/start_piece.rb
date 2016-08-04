#!/usr/bin/env ruby

fail unless ARGV.length > 0
piece_id = ARGV[0].downcase

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

case RUBY_ENGINE.to_sym
when :rbx
  Signal.trap("SIGINT") { runner.shutdown }
when :jruby
  at_exit { runner.shutdown }
else
  raise "Unsupported Ruby engine. Use Rubinius or jRuby."
end

require_relative 'demo_mesh_configuration'
require "ecell/base/sketches/#{piece_id}"
configuration = {piece_id: piece_id.to_sym, bindings: DEMO_MESH_BINDINGS}
configuration.merge! DEMO_MESH_HIERARCHY[piece_id.to_sym]
configuration.merge! ECell::Base::Sketches.const_get(piece_id.capitalize)

runner.run! configuration

