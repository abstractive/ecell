module Ef::Service::Webstack::Extensions

  extend Forwardable
  
  def_delegators :"Ef::Actor[:ClientRegistry]",
    :add_client!,
    :clients_count

  def_delegators :"Ef::Async[:ClientRegistry]",
    :close_client!,
    :clients_announce!,
    :clients_present!

end
