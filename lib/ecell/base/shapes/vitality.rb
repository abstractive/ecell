require 'ecell/elements/figure'
require 'ecell/errors'
require 'ecell/run'
require 'ecell/base/shapes/management'
require 'ecell/internals/timer'
require 'timeout'

module ECell
  module Base
    module Shapes
      class Vitality < ECell::Elements::Figure
        def initialize(options)
          super(options)
          debug(message: "Initialized", reporter: self.class) if DEBUG_DEEP
          @pieces = {}
          @waiting = []
        end

        def follower_count
          @pieces.length
        end

        def follower_map(&block)
          raise ECell::Error::MissingBlock unless block
          @pieces.keys.map { |id| block.call(id) }
        end

        def follower?(id)
          @pieces.key?(id.to_sym)
        end

        def followers?
          debug("Need: #{PIECES[ECell::Run.identity][:followers]} ... Have: #{@pieces.keys}") if DEBUG_DEEP
          PIECES[ECell::Run.identity][:followers].each { |id| return false unless follower?(id) }
          true
        end

        def follower_attach(data)
          if follower?(id = data.id)
            begin
              unless ping?(id)
                oversaw!(id)
                follower_attach(data)
              else
                return unless DEBUG_DEEP
                debug(message: "Piece already attached (#{id}) and still alive. " +
                      "Ignoring excess announcement",
                        reporter: self.class)
              end
            rescue => ex
              caught(ex, "Failure reattaching management socket.")
              return oversaw!(id)
            end
          else
            return if @waiting.include?(data.id)
            @waiting << data.id
            ECell.instruct_sync(data).attach! { |rpc|
              unless rpc && rpc.reply?(:ok)
                debug("Failure attaching: #{rpc}", reporter: self.class)
                oversaw!(id)
              else
                @waiting.delete(id)
                oversee! rpc.id
                symbol!(:got_follower)
                ECell.instruct_broadcast.welcome!(rpc.id)
                ECell::Run.subject.event!(:attaching, rpc)
              end
            }
          end
        end

        def oversee!(id)
          @pieces[id] = {}
          @pieces[id][:oversight] = after(INTERVALS[:before_oversight]) {
            heartbeating(id)
            pinging(id)
            auditing_threads(id)
          }
        end

        def oversaw!(id)
          @pieces[id].each { |key,timer|
            timer.cancel rescue nil
          }
        rescue
        ensure
          @pieces.delete(id)
        end

        def ping?(id)
          ECell.instruct_sync(id).ping! { |rpc|
            if rpc.reply?(:pong)
              symbol!(:got_pong)
              true
            else
              false
            end
          }
        rescue => ex
          caught(ex, "Failure in ping/pong test for #{id}.")
          false
        end

        def audit_threads!(id)
          ECell.instruct_sync(id).system_check!
        rescue => ex
          caught(ex, "Failure in system check #{id}.")
          respawn(id)
          false
        end

        def heartbeat!(id)
          debug(message: "Received heartbeat from #{id}", reporter: self.class) if DEBUG_DEEP
          heartbeating(id)
        end

        private

        def pinging(id)
          @pieces[id][:ping].cancel rescue nil
          @pieces[id][:ping] = every(INTERVALS[:ping]) {
            timer = ECell::Internals::Timer.now
            begin
              respawn(id) unless ping?(id)
            rescue => ex
              caught(ex, "Error pinging.")
              respawn(id)
            rescue Timeout::Error
              respawn(id, "No :pong in #{"%0.4f" % timer.stop}s.")
            end
          }
        end

        def auditing_threads(id)
          @pieces[id][:audit_threads].cancel rescue nil
          @pieces[id][:audit_threads] = every(INTERVALS[:audit_threads]) {
            begin
              rpc = audit_threads!(id)
              if rpc.error?
                restart!(id, rpc.type)
              elsif data = rpc[:returns]
                unless data[:threads].is_a?(Hash)
                  restart!(id, :invalid_vitals)
                else
                  if data[:threads][:total] > VITALITY[:max_threads]
                    restart!(id, :thread_leak)
                  else
                    clean = true
                    if data[:threads][:terminated][:exception] > 0
                      log_warn("[#{id}] #{data[:threads][:terminated][:exception]} threads terminated by exception.")
                      clean = false
                    end
                    if data[:threads][:aborted] > 0
                      log_warn("[#{id}] #{data[:threads][:aborted]} threads were aborted.")
                      clean = false
                    end
                    if clean
                      console(scope: :vitality, tag: id, message: "Seems healthy.")
                    else
                      log_warn("[#{id}] is showing slight, non-critical signs of trouble.")
                    end
                  end
                end
              else
                restart!(id, :empty_vitals)
              end
            rescue => ex
              caught(ex, "Error auditing threads.")
            end
          }
        end

        def heartbeating(id)
          @pieces[id][:heartbeat].cancel rescue nil
          @pieces[id][:heartbeat] = after(INTERVALS[:heartbeat]+INTERVALS[:margin]) {
            respawn(id, "No heartbeat in #{INTERVALS[:heartbeat]+INTERVALS[:margin]}s.")
            #de Unless a heartbeat happens after X seconds, begin respawn.
          }
        end

        def restart!(id, reason)
          log_warn("Issuing restart instruction on :#{id}, for reason: #{reason}", scope: :vitality)
          ECell.instruct_sync(id).restart_piece! { |rpc|
            if rpc.reply?(:ok)
              console("[#{id}] Accepted restart instruction.", scope: :vitality)
            else
              error("Would/will pursue hard reset or shutdown of :#{id} here, for: #{reason}", scope: :vitality)
            end
          }
        end

        def respawn(id, reason=nil)
          return unless ECell::Run.online?
          @pieces[id][:ping].cancel rescue nil
          reason = ": #{reason}" if reason
          debug(message: "May need to respawn :#{id}#{reason}.", scope: :vitality)
          sleep INTERVALS[:second_chance]
          return pinging(id) if ping?(id)
          sleep INTERVALS[:third_chance]
          return pinging(id) if ping?(id)
          debug(message: "Piece missing: #{id}", scope: :vitality, banner: true)
          #de TODO: Remove from leader's @pieces Array, reassess the Piece's own state.
          #de       Without this missing Piece, must the Leader revert to :attaching for example?
        end

      end
    end
  end
end

