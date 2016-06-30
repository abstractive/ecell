require 'ecell/elements/figure'
require 'ecell/extensions'
require 'ecell/run'

module ECell
  module Base
    module Shapes
      class Distribution < ECell::Elements::Figure
        lines :distribution_push,
              :distribution_pull,
              :distribution_pull2

        module Distribute
          #benzrf TODO: figure out Distribute
        end

        module Process
          include ECell::Extensions

          def distribution_root(piece_id, line_id=:distribution_pull2)
            "tcp://#{bindings[piece_id][:interface]}:#{bindings[piece_id][line_id]}"
          end

          def distribution_input!(type)
            distribution_root(leader, :"distribution_#{type}_push2")
          end

          def connect_distribution_output!
            distribution_push.connect = distribution_root(leader)
            distribution_push.online! if distribution_push.engaged?
            symbol!(:touched_work)
          end

          def on_task(rpc)
            distribution_push << case rpc.work
            when :ready?
              #de TODO: Check vitals, then answer.
              report!(rpc, :yes)
            else
              subj = ECell::Run.subject
              owner = subj.class.method_defined?(rpc.call) &&
                subj.class.instance_method(rpc.call).owner
              if owner == subj.class::Operations
                report!(rpc, :ok, returns: subj.send(*rpc.executable))
              else
                error!(:method_missing)
              end
            end
          end
        end
      end
    end
  end
end

