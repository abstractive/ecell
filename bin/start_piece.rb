#!/usr/bin/env ruby

fail unless ARGV.length > 0 and ARGV[0].is_a?(String)
piece_id = ARGV[0].downcase
Bundler.setup


$LOAD_PATH.push(File.expand_path("../../lib", __FILE__))
require 'celluloid/current'
require 'ecell/constants'
require 'ecell/run'

Celluloid.shutdown_timeout = ECell::Constants::INTERVALS[:max_graceful]
module Celluloid
  class << self
    @shutdown_registered = true #de We will kill it ourselves.
  end
end

deconstructor = ->{
  ECell::Run.shutdown
}

case RUBY_ENGINE.to_sym
when :rbx
  Signal.trap("SIGINT") { deconstructor.call }
when :jruby
  at_exit { deconstructor.call }
else
  raise "Unsupported Ruby engine. Use Rubinius or jRuby."
end

require "ecell/base/sketches/#{piece_id}"
ECell::Run.run! ECell::Base::Sketches.const_get(piece_id.capitalize), piece_id: piece_id.to_sym

