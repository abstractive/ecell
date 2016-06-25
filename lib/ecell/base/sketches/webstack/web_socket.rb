require 'rack'
require 'websocket_parser'
require 'celluloid/current'
require 'celluloid/io'
require 'forwardable'
require 'ecell/internals/actor'
require 'ecell/base/sketches/webstack/extensions'

require 'ecell/base/sketches/webstack'

class ECell::Base::Sketches::Webstack::WebSocket < ECell::Internals::Actor
  extend Forwardable
  include ECell::Base::Sketches::Webstack::Extensions

  BUFFER_SIZE = 16384
  attr_accessor :online

  def_delegators :@parser,
    :next_message,
    :next_messages,
    :on_message,
    :on_error,
    :on_close,
    :on_ping,
    :on_pong

  def initialize(env)
    headers!(env)
    @uuid = env['websocket_uuid']
    secure = Rack::Request.new(env).ssl?
    scheme = secure ? 'wss:' : 'ws:'
    @topic = env['REQUEST_URI']
    @url = scheme + '//' + env['HTTP_HOST'] + env['REQUEST_URI']
    env['rack.hijack'].call
    @io = Celluloid::IO::TCPSocket.new env['rack.hijack_io']
    @parser = ::WebSocket::Parser.new
    @online = true
  rescue => ex
    raise exception(ex, "Failure initializing websocket.")
  end

  def attach!
    #de This defer is critical, so Puma threads don't get blocked.
    #de This ends up using the Celluloid internal thread pool for "tasks",
    #de handling emits... as well as the WebSocket actor we're defining here.
    defer {
      loop {
        break unless @online
        begin
          until msg = @parser.next_message
            @parser.append @io.readpartial(BUFFER_SIZE)
          end
        rescue
          break
        end
      }
    }
  rescue Celluloid::TaskTerminated
    #de We don't care about this kind of exception:
    #de The WebSocket client was terminated somewhere.
    #de But... since we are using a defer {} call,
    #de the task happens outside the actor itself.
    #de So that is why we get a TaskTerminated error
    #de rather than catch disconnects purely inside actors.
  rescue => ex
    raise exception(ex, "Outer attach failure.")
  end

  def send(message)
    write ::WebSocket::Message.new(message).to_data
  rescue
    close!
  end

  alias_method :<<, :send

  def write(data)
    @io << data
  rescue IOError, Errno::ECONNRESET, Errno::EPIPE
    close!
  end

  def cancel_timers!
    if @timers
      @timers.each { |timer|
        begin
          timer.cancel
        rescue
        end
        timer = nil
      }
    end
    @timers.compact!
  end

  def disconnect
    @online = false
    cancel_timers!
    @io.close unless @io.closed?
  rescue
  end

  def close!
    disconnect
    close_client!(@uuid)
  end

  def headers!(env)
    @headers = {
      "Upgrade" => env['HTTP_UPGRADE'],
      "Sec-Websocket-Key" => env['HTTP_SEC_WEBSOCKET_KEY'],
      "Sec-Websocket-Version" => env['HTTP_SEC_WEBSOCKET_VERSION']
    }
  end
end

require 'ecell/base/sketches/webstack/web_socket/emitters'

