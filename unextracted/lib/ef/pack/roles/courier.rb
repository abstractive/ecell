require 'ef/pack/capacity/calling/courier'

module Ef::Pack::Courier
  Capacities = [
    {
      as: :calling,
      type: Ef::Pack::Capacity::Calling,
      channels: {
        answering_router: {mode: :binding},    #de Receive brokered calls.
        calling_router: {mode: :binding}     #de Making a brokered call.
      }
    }
  ]
  class << self    
    def Defaults
      {
        emitters: {
          starting: [
            [:answering_router, :from_petitioner],
            [:calling_router, :from_respondent]
          ]
        }
      }
    end
  end
  module Methods
    include Ef::Pack::Capacity::Calling::Courier
  end
end
