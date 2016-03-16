#!/usr/bin/env ruby

fail unless ARGV.length > 0 and ARGV[0].is_a?(String)
service = ARGV[0].downcase
Bundler.setup


$LOAD_PATH.push(File.expand_path("../../lib", __FILE__))
require "ef/service"

Celluloid.shutdown_timeout = Ef::Constants::INTERVALS[:max_graceful]
module Celluloid
  class << self
    @shutdown_registered = true #de We will kill it ourselves.
  end
end

deconstructor = ->{
  Ef::Service.shutdown
}

case RUBY_ENGINE.to_sym
when :rbx
  Signal.trap("SIGINT") { deconstructor.call }
when :jruby
  at_exit { deconstructor.call }
else
  raise "Unsupported Ruby engine. Use Rubinius or jRuby."
end

Ef::Service.send :"#{service}!"
