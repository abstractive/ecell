Overview
========

Refactored version of a sample web server based on:

* JRuby
* Puma
* Rack
* Sinatra
* Celluloid
* Ef::Service::Pack

Serves:

* REST routes (http://) - via Sinatra
* Websocket connections (ws://) - via Faye::Websocket
* Adobe Flash Policy File requests (XMLSocket:://)

...all on the same port.

Includes a simple Flex / Flash based client for testing.

Usage
=====

### Managing the Webstack service.

This is the Webstack service of the EnergyFlow Service Pack. It is started and stopped either:

* Indirectly starting and stopping as part of the pack: **( recommended )**
  * `bin/ef_service start`
  * `bin/ef_service shutdown`
  * `bin/ef_service restart`

* Directly starting and stopping only this service:
  * `bin/ef_service webstack start`
  * `bin/ef_service webstack stop`
  * `bin/ef_service webstack restart`

### Testing Sinatra routes:

**Visit:** http://localhost:4567

**Or use `curl` as follows:**

```
curl http://localhost:4567/index.html
```

### Testing Socket Policy File and WebSockets

Invoke the Flash websocket test page with your default browser:

**Visit:** [http://localhost:4567/WebSocketClient.swf](http://localhost:4567/WebSocketClient.swf)

Then:

* Choose one or both of the client sections to connect.
  * Each section can connect to the same topic or different topics by using the request URI.
* Click on the 'Connect' button.
  * This will make a connection on the same host and port that served the .swf file and the predefined topic (e.g. ws1 or ws2).
* Enter a message in the text field at the bottom of the window and press 'Send'.
* Optionally 'Close' the connection.
  * WebSocket connections to any port / host / topic may be made by pressing 'Close' then entering ws://<hostname>:<port>/<topic> into the text field and then clicking 'Connect'.
