#!/usr/bin/env ruby

$LOAD_PATH.push(File.expand_path("../../lib", __FILE__))

module Ef
  require "ef/constants"
    require "ef/timer"
  class Service
    require "ef/pack/availability"
  end
end

include Ef::Constants

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


SERVICES.each { |identity,options|
  if BINDINGS[identity]
    BINDINGS[identity].each { |channel, port|
      waited = Ef::Timer.begin
      begin
        unless Ef::Service.port_available?(SERVICES[identity][:interface], port)
          unless waiting
            puts "Checking if ports are available for all services..."
            waiting = true
          end
          print ">> "
          print "#{channel}@#{identity} needs:".ljust(40)
          print "#{SERVICES[identity][:interface]}:#{port} ".ljust(20)
          Ef::Service.wait_for_port(SERVICES[identity][:interface], port)
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
