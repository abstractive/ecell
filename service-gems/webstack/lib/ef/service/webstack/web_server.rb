# A sample web server serving
#     http://         REST routes using Sinatra
#     ws://           websocket traffic using WebSocket::Parser and Celluloid
#     xmlsocket://    Flash Policy File requests
# on the same port
#
# Author: Harley Mackenzie
# Revamper: digitalextremist //
#
# Copyright (c) 2014 Energy One Limited

class Ef::Service::Webstack::WebServer < Ef::Pack::Actor

  include Ef::Service::Webstack::Extensions
  include Ef::Service::Webstack::WebSocket::Mixins

  def initialize(app)
    @app = app
  end

  def call(env)
    debug(message: "Request environment.", store: env, reporter: self.class) if DEBUG_HTTP

    if env['REQUEST_PATH'] == POLICY_FILE_REQUEST_PATH
      debug(message: "sending policy file direct response through puma socket", reporter: self.class) if DEBUG_HTTP && DEBUG_DEEP

      connection_socket = env["puma.socket"]
      connection_socket.print('<?xml version="1.0"?><cross-domain-policy><allow-access-from domain="*" to-ports="*"/></cross-domain-policy>') 
      connection_socket.close

      return RACK_HANDLED_RESPONSE
    elsif websocket?(env)
      debug(message: "creating a websocket connection", reporter: self.class) if DEBUG_HTTP && DEBUG_DEEP
      websocket!(env)
      debug(message: "websocket connection created", reporter: self.class) if DEBUG_HTTP && DEBUG_DEEP

      if DEBUG
        begin
          clients_present!
        rescue => ex
          raise exception(ex, "Dead registry?")
        end
      end

      return RACK_HANDLED_RESPONSE
    else
      debug(message: 'call Sinatra for handling request', reporter: self.class) if DEBUG_HTTP
      Timeout.timeout(INTERVALS[:pageload]) {
        return @app.call(env)
      }
    end
  rescue Timeout::Error
    debug("Timeout on request: #{env["PATH_INFO"]}")
    return
  rescue => ex
    caught(ex, "Bad request.")
    return
  end

end
