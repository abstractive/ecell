# A sample web server serving
#     http://         routes using Sinatra
#     ws://           websocket traffic using WebSocket::Parser and Celluloid
#     xmlsocket://    Flash Policy File requests
# on the same port
#
# Author: Harley Mackenzie
# Revamper: digitalextremist //
#
# Copyright (c) 2014 Energy One Limited
require 'timeout'
require 'ecell/internals/actor'
require 'ecell/base/sketches/webstack/web_socket'
require 'ecell/base/sketches/webstack/extensions'
require 'ecell/base/sketches/webstack/puma'

require 'ecell/base/sketches/webstack/shape'

class ECell::Base::Sketches::WebstackShape::WebServer < ECell::Internals::Actor
  include ECell::Base::Sketches::WebstackShape::Extensions

  def initialize(app)
    @app = app
  end

  #de Detection method ported from the websocket_driver gem
  def websocket?(env)
    connection = env['HTTP_CONNECTION'] || ''
    upgrade = env['HTTP_UPGRADE'] || ''

    env['REQUEST_METHOD'] == 'GET' and
        connection.downcase.split(/\s*,\s*/).include?('upgrade') and
        upgrade.downcase == 'websocket'
  end

  def websocket!(env)
    ws = ECell::Base::Sketches::WebstackShape::WebSocket.new(env)
    debug(message: "Added physical connection.", reporter: self.class) if DEBUG_HTTP
    ws.emitters!
    debug(message: "Added emitters to socket.", reporter: self.class) if DEBUG_HTTP
    ws.async.attach! #de ws.read_every 0.51
    debug(message: "Attached socket.", reporter: self.class) if DEBUG_HTTP
  end

  def call(env)
    debug(message: "Request environment.", store: env.inspect, reporter: self.class) if DEBUG_HTTP

    if env['REQUEST_PATH'] == ::POLICY_FILE_REQUEST_PATH
      debug(message: "sending policy file direct response through puma socket", reporter: self.class) if DEBUG_HTTP && DEBUG_DEEP

      connection_socket = env["puma.socket"]
      connection_socket.print('<?xml version="1.0"?><cross-domain-policy><allow-access-from domain="*" to-ports="*"/></cross-domain-policy>')
      connection_socket.close

      return ::RACK_HANDLED_RESPONSE
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

      return ::RACK_HANDLED_RESPONSE
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

