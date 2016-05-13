require 'pp'
require 'rack'
require 'rack/handler'
require 'puma'
require 'puma/client'

POLICY_FILE_REQUEST_STRING = "<policy-file-request/>\000"
POLICY_FILE_REQUEST_PATH = '/policy-file-request'
RACK_HANDLED_RESPONSE = [-1, {}, []]
KEEPALIVE_TIME = 15 # in seconds

module Puma

  #
  # A facade class around the puma HttpParser class to intercept and serve
  # Adobe Flash Policy File server requests (XMLSocket://)
  #
  # Author: Harley Mackenzie
  #
  # Copyright (c) 2014 Energy One Limited
  #
  class HttpParserFacade

    # create new facade class and store the old parser reference
    def initialize(puma_parser)
      @puma_parser = puma_parser
    end

    # intercept policy file request and turn it into a valid http GET
    def execute(req_hash, data, start)
      if (data == POLICY_FILE_REQUEST_STRING)
        req_hash['SERVER_PROTOCOL'] = '"HTTP/1.0'
        data = "GET #{POLICY_FILE_REQUEST_PATH} HTTP/1.0\r\n\r\n"
      end

      return @puma_parser.execute(req_hash, data, start)
    end

    # all of the other routines simply defer to the puma parser

    def body
      return @puma_parser.body
    end

    def error?
      return @puma_parser.error?
    end

    def finish
      return @puma_parser.finish
    end

    def finished?
      return @puma_parser.finished?
    end

    def nread
      return @puma_parser.nread
    end

    def reset
      return @puma_parser.reset
    end

  end
  
  # create new initialize constructor and reassign parser call to our facade class

  class Client
    alias_method :puma_initialize, :initialize

    def initialize(io, env=nil)
      puma_initialize(io, env)
      @parser = HttpParserFacade.new(@parser)
    end
  end

end
