require 'ecell/base/designs/manager'
require 'ecell/base/designs/answerer'
require 'ecell/base/designs/caller'
require 'ecell/base/designs/coordinator'

require 'ecell/base/sketches/process/shape'

module ECell
  module Base
    module Sketches
      process_design = [
        {
          as: :process_figure,
          shape: ProcessShape
        }
      ]

      Process = {
        designs: [
          ECell::Base::Designs::Manager,
          ECell::Base::Designs::Answerer,
          ECell::Base::Designs::Caller,
          ECell::Base::Designs::Coordinator,
          process_design
        ],
        call_handler: :process_figure
      }
    end
  end
end
