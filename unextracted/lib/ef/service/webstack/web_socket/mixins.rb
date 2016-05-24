module Ef::Service::Webstack::WebSocket::Mixins

  include Ef::Pack::Extensions

  #de Detection method ported from the websocket_driver gem
  def websocket?(env)
    connection = env['HTTP_CONNECTION'] || ''
    upgrade = env['HTTP_UPGRADE'] || ''

    env['REQUEST_METHOD'] == 'GET' and
        connection.downcase.split(/\s*,\s*/).include?('upgrade') and
        upgrade.downcase == 'websocket'
  end

  def websocket!(env)
    ws = Ef::Service::Webstack::WebSocket.new(env)
    debug(message: "Added physical connection.", reporter: self.class) if DEBUG_HTTP
    ws.emitters!
    debug(message: "Added emitters to socket.", reporter: self.class) if DEBUG_HTTP
    ws.async.attach! #de ws.read_every 0.51
    debug(message: "Attached socket.", reporter: self.class) if DEBUG_HTTP
  end

end
