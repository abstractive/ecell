require 'celluloid/zmq'

#de TODO: Use different thread-counts for different types of conduit.
Celluloid::ZMQ.init(9)

module Ef::Pack::Conduit
  class << self

    include Ef::Pack::Extensions

    def interface(service)
      return DEFAULT_INTERFACE unless SERVICES[service] && SERVICES[service][:interface]
      SERVICES[service][:interface]
    end

    def port(service, channel)
      return DEFAULT_PORT unless BINDINGS[service] && BINDINGS[service][channel]
      BINDINGS[service][channel]
    end

    CHANNELS.each { |channel|
      define_method("#{channel}?") {
        begin
          Ef::Actor[channel] && Ef::Actor[channel].online
        rescue => ex
          caught(ex, "Trouble checking channel: #{channel}")
          false
        end
      }
      define_method(channel) {
        Ef::Actor[channel]
      }
    }

    def channels(&block)
      CHANNELS.inject([]) { |c,channel|
        c << channel if send(:"#{channel}?")
        c
      }
    end

    def each_channel
      channels.each { |c| yield(c) }
    end

    def endpoints
      channels.inject({}) { |endpoints,channel|
        begin
          if endpoint = Ef::Actor[channel].endpoint
            endpoints[channel] = endpoint
          end
        rescue => ex
          caught(ex, "Trouble getting endpoing for channel: #{channel}")
        end
        endpoints
      }
    end

  end
end

require 'ef/pack/conduit/channel'
require 'ef/pack/conduit/handlers'
require 'ef/pack/conduit/sockets'
