require 'ecell/internals/actor'
require 'ecell/run'

require 'ecell/base/sketches/webstack/shape'

class ECell::Base::Sketches::WebstackShape::ClientRegistry < ECell::Internals::Actor
  #de This is a specialized implementation of what ends up being a "concurrent hash"
  #de This satisfies the requirement of a thread-safe registry.

  def initialize
    # The registry is a 2-dimensional hash, the first level is the hash of topics, the second level is the hash of clients for a topic.
    # When a topic is requested from the registry, create an empty hash for it.
    @registry = Hash.new { |registry, topic| registry[topic] = {} }

    at_exit {
      evacuate!
    }
  end

  #de Below, `#announce!` could have been called before the client was added to the registry.
  #de That would have avoided the need for the `except` parameter on `#announce!`
  #de But the below order is kept to demonstrate sending announcements to all but one `uuid`.
  def add_client!(client, topic = nil)
    debug(message: "Adding client socket to registry.", reporter: self.class) if DEBUG_SOCKET
    @registry[topic][uuid = uuid!] = client
    clients_announce! "CONNECT: #{uuid}", topic, uuid if DEBUG_PIECES
    debug(message: "Added client to registry: #{uuid}.", reporter: self.class) if DEBUG_SOCKET
    uuid
  end

  #dk if provided topic is NIL, messages will be announced to ALL registered clients
  def clients_announce!(message, topic=nil, except=nil)
    @registry.each { |registered_topic, clients|
      clients.each { |uuid, client|
        if topic.nil? || topic == registered_topic
          if client.alive?
            client.send(message) unless uuid == except
          else
            close(uuid)
          end
        end
      }
    }
  end

  def clients_present!
    clients_announce! "Connected clients: #{size}" if DEBUG_PIECES
    console(message: "connected clients: #{size}", reporter: self.class) if DEBUG_SOCKET
  end

  def delete(uuid)
    debug(message: "deleting client: #{uuid}", reporter: self.class) if DEBUG_SOCKET
    begin
      each_topic { |topic, clients|
        client = clients[uuid]
        if client
          #de Give the WebSocket a chance to shutdown, and avoid (harmless) TerminatedTask errors.
          client.terminate rescue nil
        end
        @registry[topic].delete(uuid)

        if @registry[topic].empty?
          debug(message: "no more clients left for topic #{topic}, removing it", reporter: self.class) if DEBUG_SOCKET
          @registry.delete(topic)
        end
      }
    rescue => ex
      caught(ex, "Error terminating web socket client.")
    end
    if DEBUG_PIECES
      clients_announce! "DISCONNECT: #{uuid}"
      clients_present!
    end
  end

  def each_client(&b)
    @registry.each_value { |clients| clients.each(&b) }
  end

  def each_topic(&b)
    @registry.each(&b)
  end

  def close_client!(uuid)
    debug(message: "closing socket for #{uuid}", reporter: self.class) if DEBUG_SOCKET
    begin
      each_topic { |topic, clients|
        client = clients[uuid]
        client.disconnect if client
      }
    rescue => ex
      caught(ex, "Error closing client socket.")
    end
    delete(uuid)
  end

  def size
    num = 0
    each_client { |uuid, client| num = num + 1 }
    num
  end

  def evacuate!
    each_client { |uuid, client| client.disconnect rescue nil }
  end

  alias_method :count, :size
  alias_method :clients_count, :size

rescue => ex
  caught(ex, "Registry error.")
end

