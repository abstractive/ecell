require 'ef/pack/capacity/calling/respondent'

module Ef::Pack::Respondent
  Capacities = [
    {
      as: :calling,
      type: Ef::Pack::Capacity::Calling,
      channels: {calling_reply: {mode: :connecting}}
    }
  ]
  class << self
    def Defaults
      {
        emitters: {
          ready: [
            [:calling_reply, :on_call],
          ]
        },
        executive_sync: {
          attaching: [
            :attach_courier_incomming!
          ]
        }
      }
    end
  end
  module Methods
    include Ef::Pack::Capacity::Calling::Respondent
  end
end
