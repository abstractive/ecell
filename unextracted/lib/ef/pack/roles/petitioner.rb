require 'ef/pack/capacity/calling/petitioner'

module Ef::Pack::Petitioner
  Capacities = [
    {
      as: :calling,
      type: Ef::Pack::Capacity::Calling,
      channels: {calling_request: {mode: :connecting}}
    }
  ]
  class << self
    def Defaults
      {
        emitters: {
          ready: [
            [:calling_request, :on_answer],
          ]
        },
        executive_sync: {
          attaching: [
            :attach_courier_outgoing!
          ]
        }
      }
    end
  end
  module Methods
    include Ef::Pack::Capacity::Calling::Petitioner
  end
end
