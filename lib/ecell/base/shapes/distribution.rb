require 'ecell/elements/figure'
require 'ecell/extensions'

module ECell
  module Base
    module Shapes
      class Distribution < ECell::Elements::Figure
        lines :distribution_push,
              :distribution_pull,
              :distribution_pull2

        module Distribute
          #benzrf TODO: figure out Distribute

          def on_followers_ready
            emitter distribution_pull2, :on_report
          end

          def on_started
            #benzrf TODO: this is definitely wrong
            # unless respond_to?(:on_report)
            #   raise ECell::Error::MissingEmitter, "No on_report emitter exists."
            # end
            # unless @line_ids.any? { |c| c.to_s.end_with?("_push2") && c.to_s.start_with?("distribution_") }
            #   raise ECell::Error::Line::Missing, "No distribution_*_push2 lines configured and initialized."
            # end
            distribution_pull2.provision!
          end
        end

        module Process
          include ECell::Extensions

          def on_setting_up
            unless distribution_pull
              raise ECell::Error::Line::Missing, "No distribution_pull line configured and initialized."
            end
            emitter distribution_pull, :on_task
          end

          def on_started
            connect_distribution_output!
          end

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
              new_return.report(rpc, :yes)
            else
              handler = configuration[:task_handler]
              handler &&= ECell.sync(handler)
              return new_return.error(rpc, :no_handler) unless handler
              owner = handler.class.method_defined?(rpc.call) &&
                handler.class.instance_method(rpc.call).owner
              if owner == handler.class::Operations
                new_return.report(rpc, :ok, returns: handler.send(*rpc.executable))
              else
                new_return.error(rpc, :method_missing)
              end
            end
          end
        end
      end
    end
  end
end

