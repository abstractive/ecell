require 'celluloid/current'
require 'reel'
require 'ecell/elements/figure'
require 'ecell/extensions'
require 'ecell/internals/timer'
require 'ecell/base/designs/follower'

class ReelStaticPiece < ECell::Elements::Figure
  DEFAULT_ROOT = File.expand_path("../public", __FILE__)
  DEFAULT_PORT = 4567

  class Server < Reel::Server::HTTP
    include ECell::Extensions

    def initialize(frame)
      @frame = frame
      @root = configuration[:reel_root]        || DEFAULT_ROOT
      host  = bindings[piece_id][:interface]   || DEFAULT_INTERFACE
      port  = bindings[piece_id][:http_server] || DEFAULT_PORT
      super(host, port, &method(:on_connection))
    end

    def on_connection(connection)
      connection.each_request do |request|
        timer = ECell::Internals::Timer.begin
        handle_request(request)
        stats = {
          url: request.url,
          time: timer.stop,
          method: request.method,
          host_addr: request.remote_addr
        }
        info("Served a request: #{stats}")
      end
    end

    def handle_request(request)
      path = File.join(@root, request.path)
      begin
        File.open(path) do |f|
          raise Errno::EISDIR unless f.lstat.file?
          request.respond(:ok, f)
        end
      rescue Errno::ENOENT
        request.respond(404, "error 404")
      rescue Errno::EISDIR, Errno::EACCES
        request.respond(403, "error 403")
      end
    end
  end

  def on_setting_up
    ECell.supervise(type: Server, as: :reel_server, args: [frame])
  end

  def shutdown
    ECell.sync(:reel_server).terminate
    super
  end
end

ReelStatic = {
  designs: [
    ECell::Base::Designs::Follower,
    [
      {
        as: :reel_static_piece,
        type: ReelStaticPiece
      }
    ]
  ]
}

