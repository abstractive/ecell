#!/usr/bin/env ruby

$LOAD_PATH.push(File.expand_path("../../lib", __FILE__))

require 'ecell/constants'
require 'ecell/internals/timer'
require 'ecell/run'

include ECell::Constants

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


PIECES.each { |identity,options|
  if BINDINGS[identity]
    BINDINGS[identity].each { |line, port|
      waited = ECell::Internals::Timer.begin
      begin
        unless ECell::Run.port_available?(PIECES[identity][:interface], port)
          unless waiting
            puts "Checking if ports are available for all pieces..."
            waiting = true
          end
          print ">> "
          print "#{line}@#{identity} needs:".ljust(40)
          print "#{PIECES[identity][:interface]}:#{port} ".ljust(20)
          ECell::Run.wait_for_port(PIECES[identity][:interface], port)
          print "Available: took #{"%0.4f" % (waited.stop)} seconds to free up."
          print "\n"
        end
        @success = true
      ensure
        waited.stop && waited = nil
      end
    }
  end
}

