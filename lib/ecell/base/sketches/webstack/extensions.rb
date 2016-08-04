require 'forwardable'
require 'ecell'
require 'ecell/elements/figure'

module ECell
  module Base
    module Sketches
      class WebstackShape < ECell::Elements::Figure
        module Extensions
          extend Forwardable

          def_delegators :"ECell.sync(:ClientRegistry)",
            :add_client!,
            :clients_count,
            :close_client!,
            :clients_announce!,
            :clients_present!
        end
      end
    end
  end
end

