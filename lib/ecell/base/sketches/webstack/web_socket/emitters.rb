require 'websocket_parser'
require 'celluloid/current'
require 'ecell/extensions'
require 'ecell/base/sketches/webstack/extensions'

require 'ecell/base/sketches/webstack/web_socket'

class ECell::Base::Sketches::Webstack::WebSocket
  include ECell::Extensions
  include ECell::Base::Sketches::Webstack::Extensions

  def emitters!
    @timers = []
    @uuid = add_client!(Celluloid::Actor.current, @topic)

    # TODO: create a new timer for the added client, reset it on every ping and remove the client from the registry if it's not pinging anymore.
    handshake = ::WebSocket::ClientHandshake.new(:get, @url, @headers)

    if handshake.valid?
      response = handshake.accept_response
      response.render(@io)
      debug(message: "#{[:open, @uuid]}", reporter: self.class) if DEBUG_PIECES

      console(message: "sending hello message through recently opened socket", reporter: self.class) if DEBUG_SOCKET
      send "Hello from the ECell message server."
      send "CLIENT ID: #{@uuid}"

      @inactivity_timer = after(INTERVALS[:client_inactivity]) {
        console(message: "Inactivity timeout triggered for client #{@uuid} after #{INTERVALS[:client_inactivity]} seconds!", reporter: self.class)
        close!
      }

      @timers << @inactivity_timer

    else
      close!
    end

    on_close { |status, reason|
      debug(message: "#{[:close, @uuid, status, reason]}", reporter: self.class) if DEBUG_PIECES
      # According to the spec the server must respond with another
      # close message before closing the connection
      write ::WebSocket::Message.close.to_data
      close!
    }

    on_ping { |payload|
      debug(message: "#{[:ping, @uuid, payload]}", reporter: self.class) if DEBUG_PIECES
      reset_inactivity_timer
      write ::WebSocket::Message.pong(payload).to_data
    }

    on_pong { |payload|
      debug(message: "#{[:pong, @uuid, payload]}", reporter: self.class) if DEBUG_PIECES
      reset_inactivity_timer
    }

    on_error { |message|
      console(message: "hit an error: #{message}", reporter: self.class) if DEBUG_PIECES
      close!
    }

    # publish the received message
    on_message { |message|
      debug(message: "#{[:message, @uuid, message]}", reporter: self.class) if DEBUG_PIECES
      if !message.empty?
        begin
          if DEBUG_PIECES
            console(message: "broadcasting message: '#{message}' to #{clients_count} connected clients", reporter: self.class)
            message = "#{@uuid}: " + message
          end
          clients_announce!(message, @topic)
        rescue => ex
          raise exception(ex, "Error on_message.")
        end
      elsif DEBUG_PIECES
        console(message: "empty message sent by #{@uuid}", reporter: self.class)
      end
      reset_inactivity_timer
    }

    debug(message: "#{[:monitoring, @uuid]}", reporter: self.class) if DEBUG_SOCKET

  rescue => ex
    raise exception(ex, "Failure setting emitters.")
  end

  def reset_inactivity_timer
    console(message: "resetting inactivity timer for client #{@uuid}", reporter: self.class) if DEBUG_SOCKET
    @inactivity_timer.reset
  end
end

