#!/usr/bin/env ruby

fail unless ARGV.length > 0 and ARGV[0].is_a?(String)
piece_id = ARGV[0].downcase

require 'bundler/setup'
Bundler.setup
require 'celluloid/current'
require 'ecell/constants'
require 'ecell/run'

Celluloid.shutdown_timeout = ECell::Constants::INTERVALS[:max_graceful]
module Celluloid
  class << self
    @shutdown_registered = true #de We will kill it ourselves.
  end
end

Signal.trap('INT') { ECell::Run.shutdown }


require_relative 'demo_mesh_configuration'
log_dir = File.expand_path("../logs", __FILE__)
configuration = {
  piece_id: piece_id.to_sym,
  bindings: DEMO_MESH_BINDINGS,
  log_dir: log_dir
}.merge(DEMO_MESH_HIERARCHY[piece_id.to_sym])

require "ecell/base/sketches/#{piece_id}"
ECell::Run.run! ECell::Base::Sketches.const_get(piece_id.capitalize), configuration

