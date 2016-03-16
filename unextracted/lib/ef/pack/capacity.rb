class Ef::Pack::Capacity < Ef::Pack::Actor

  include Ef::Pack::Extensions

  def initialize(options)
    @options = options
    @sockets = {}
  end

  def shutdown
    @sockets.inject([]) { |shutdown,(channel,socket)|
      shutdown << socket.future.transition(:shutdown)
    }.map(&:value)
  end

  def relayer(from, to)
    debug(message: "Setting a relay from #{from}, to #{to}") if DEBUG_INJECTIONS
    if @sockets[to].ready?
      @sockets[from].reader { |data|
        @sockets[to] << data
      }
    end
  rescue => ex
    caught(ex, "Trouble with relayer.") if Ef::Service.online?
    return
  end

  CHANNELS.each { |channel|
    define_method(:"#{channel}?") { @sockets[channel] && @sockets[channel].online } 
    define_method(channel) { |options={}| @sockets[channel] || raise(Ef::Channel::Error::Uninitialized) }
  }

  def initialize_channel(channel, options)
    @sockets[channel] = super
  rescue => ex
    raise exception(ex, "Channel Supervision Exception")
  end

end

require 'ef/pack/capacity/logging'
require "ef/pack/capacity/spool"
#de require 'set'

Ef::Supervise(as: :spool, type: Ef::Pack::Capacity::Spool)

require 'ef/pack/capacity/presence'
require 'ef/pack/capacity/assertion'
require 'ef/pack/capacity/calling'
require 'ef/pack/capacity/operative'
require 'ef/pack/capacity/vitality'
require 'ef/pack/capacity/database'

#de TODO: Only necessary for pure Leader services, not even Managers.
Ef::Pack::Capacity::Logging::STORAGE = case Ef::Constants::LOG_STORAGE
                                       when :file
                                         Ef::Pack::Capacity::Logging::Storage::File
                                       when :database
                                         Ef::Pack::Capacity::Logging::Storage::Database
                                       else
                                         raise "No log storage mode specified."
                                       end
