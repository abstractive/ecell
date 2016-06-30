#!/usr/bin/env ruby

$LOAD_PATH.push(File.expand_path("../../lib", __FILE__))
require 'ecell/internals/timer'
require 'ecell/run'

@success = false
deconstructor = ->{
  exit!(@success === true ? 0 : 1)
}

case RUBY_ENGINE.to_sym
when :rbx
  Signal.trap("SIGINT") { deconstructor.call }
when :jruby
  at_exit { deconstructor.call }
else
  raise "Unsupported Ruby engine. Use Rubinius or jRuby."
end

waiting = false

require_relative 'demo_mesh_configuration'

DEMO_MESH_BINDINGS.each { |piece_id,options|
  options.each { |line, port|
    next if line == :interface
    waited = ECell::Internals::Timer.begin
    begin
      unless ECell::Run.port_available?(options[:interface], port)
        unless waiting
          puts "Checking if ports are available for all pieces..."
          waiting = true
        end
        print ">> "
        print "#{line}@#{piece_id} needs:".ljust(40)
        print "#{options[:interface]}:#{port} ".ljust(20)
        ECell::Run.wait_for_port(options[:interface], port)
        print "Available: took #{"%0.4f" % (waited.stop)} seconds to free up."
        print "\n"
      end
      @success = true
    ensure
      waited.stop && waited = nil
    end
  }
}

