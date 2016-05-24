class Ef::Service::Webstack < Ef::Pack::Service

  PUBLIC_ROOT = File.expand_path("../../../../public", __FILE__)
  
  require 'ef/service/webstack/extensions'
  require 'ef/service/webstack/puma'
  require 'ef/service/webstack/handler'
  require 'ef/service/webstack/routes'
  require 'ef/service/webstack/web_socket'
  require 'ef/service/webstack/client_registry'
  require 'ef/service/webstack/web_socket/mixins'
  require 'ef/service/webstack/web_socket/emitters'
  require 'ef/service/webstack/web_server'

  require 'ef/service/webstack/rpc'
  require 'ef/service/webstack/automata'
  include Ef::Service::Webstack::Automata
  include Ef::Service::Webstack::RPC

  def initialize(configuration={})
    role! Ef::Pack::Member,
          Ef::Pack::Petitioner,
          Ef::Pack::Respondent
    super(configuration)
  rescue => ex
    raise exception(ex, "Failure initializing.")
  end

end
