require 'ecell/elements/figure'
require 'ecell/run'

module ECell
  module Base
    module Shapes
      class Operative < ECell::Elements::Figure
        def coordinator_pull_root(line_id=:coordinator_pull)
          #benzrf TODO: figure out proper coordinator-identification logic
          piece_id = SERVICES[ECell::Run.identity][:leader] || DEFAULT_LEADER
          "tcp://#{PIECES[piece_id][:interface]}:#{BINDINGS[piece_id][line_id]}"
        end

        def connect_coordinator_output!
          operative_push.connect = coordinator_pull_root()
          operative_push.online! if operative_push.engaged?
          symbol!(:touched_work)
        end

        def coordinator_input!(type)
          coordinator_pull_root(:"coordinator_#{type}_push")
        end

        def on_operation(rpc)
          operative_push << case rpc.work
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

