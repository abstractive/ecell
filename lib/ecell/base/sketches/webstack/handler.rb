require 'sinatra'
require 'ecell/internals/actor'
require 'ecell/run'
require 'ecell/base/sketches/webstack/web_server'
require 'ecell/base/sketches/webstack/routes'
require 'ecell/base/sketches/webstack/puma'

#de Custom refactor/cleaning of Rack::Handler::Puma
#de Wrapped as an actor, so as not to block the Piece.

require 'ecell/base/sketches/webstack'

class ECell::Base::Sketches::Webstack::Handler < ECell::Internals::Actor
  finalizer :stop!

  WEBSTACK = {
    host: '0.0.0.0',
    threads: {
      min: 0,
      max: 16
    }
  }

  def initialize(options={})
    return unless ECell::Run.online?
    options = WEBSTACK.merge(options)
    options[:port] ||= bindings[ECell::Run.piece_id][:http_server]
    @rack ||= Rack::Builder.new do
      use ECell::Base::Sketches::Webstack::WebServer
      map( '/') {
        run ECell::Base::Sketches::Webstack::Routes
      }
    end
    @puma ||= ::Puma::Server.new(@rack)

    console(message: "Puma #{::Puma::Const::PUMA_VERSION} // " +
                     "#{options[:host]}:#{options[:port]} // " +
                     "Threads > #{options[:threads][:min]}-#{options[:threads][:max]}")

    at_exit {
      stop!
    }

    @puma.add_tcp_listener options[:host], options[:port]
    @puma.min_threads = options[:threads][:min]
    @puma.max_threads = options[:threads][:max]
    async.run!
  rescue => ex
    raise exception(ex, "Failure in rack handler initialization.", reporter: self.class)
  end

  def run!
    @puma.run.join
  rescue => ex
    raise exception(ex, "Failure in rack handler run loop.", reporter: self.class)
  end

  def stop!
    console(message: "Gracefully shutting down server.", reporter: "Puma")
    @puma.stop(true)
  rescue => ex
    caught(ex, "Failure in rack handler shutdown.", reporter: self.class)
  end
end

