require 'celluloid/current'
require 'ecell/internals/actor'
require 'ecell'

module ECell
  module Elements
    class Subject < ECell::Internals::Actor
      [:emitters, :relayers, :events].each { |layer|
        define_method(layer) { |branch=nil|
          debug("Access #{layer}#{(branch) ? " on branch #{branch}" : ""}.") if DEBUG_INJECTIONS
          @injections[layer] ||= {}
          return @injections[layer] unless branch
          @injections[layer][branch] ||= []
        }
        define_method(:"#{layer}?") { |branch=nil|
          return unless @injections[layer]
          @injections[layer].is_a?(Hash) && (
            branch.nil? ||
            @injections[layer][branch].is_a?(Array)
          )
        }
      }

      def emitter=(state, pair)
        level = emitters(state)
        #benzrf TODO: this is probably supposed to be <<
        level += pair
      end

      def executives(mode)
        @executives[mode] ||= (@injections[:"executive_#{mode}"] ||= {})
      rescue => ex
        caught(ex, "Trouble with executives[#{mode}]")
      end

      def relayers!
        unless relayers?
          debug("No relayers.", banner: true) if DEBUG_INJECTIONS
          return
        end
        relayers.each { |figure_id, pairs|
          pairs.each { |line_ids|
            debug("Access relayers! #{figure_id} ... #{line_ids}") if DEBUG_INJECTIONS
            ECell.async(figure_id).relayer(line_ids.first, line_ids.last)
          }
        }
      end

      #de Setup as dynamic/reflexive in case different kinds of emitter are needed in the future.
      def emitter!(line_id, piece_id=nil, method)
        debug("Triggering emitter, #{method}@#{line_id}.") if DEBUG_INJECTIONS
        receiver = piece_id ? ECell.sync(piece_id) : Celluloid::Actor.current
        ECell.sync(line_id).async(:emitter, piece_id, method)
      rescue => ex
        caught(ex,"Failure in emitter: #{method}@#{line_id}.")
      end

      def emitters!(level)
        return unless emitters[level].is_a?(Array)
        emitters[level].each { |args| emitter!(*args) }
        true
      rescue => ex
        caught(ex, "Trouble setting emitters.")
        false
      end

      def interpret_executive(exec)
        exec = [exec] unless exec.is_a? Array
        case exec.map &:class
        when [Symbol]
          [self, exec[0], []]
        when [Symbol, Array]
          [self, exec[0], exec[1]]
        when [Symbol, Symbol]
          [ECell.sync(exec[0]), exec[1], []]
        when [Symbol, Symbol, Array]
          [ECell.sync(exec[0]), exec[1], exec[2]]
        else
          raise ArgumentError, "Executive entries must be a symbol only, "\
            "or an array of [:symbol, :symbol (optional), args (optional)]"
        end
      end

      def executives!(level)
        debug("Access executives at level :#{level}.") if DEBUG_INJECTIONS
        (executives(:sync)[level] || []).each { |exec|
          receiver, method, args = interpret_executive(exec)
          debug("Execute: #{[method, args]}@#{receiver}/#{level}|sync", highlight: true) if DEBUG_INJECTIONS
          receiver.send(method, *args)
        }
        (executives(:async)[level] || []).each { |exec|
          receiver, method, args = interpret_executive(exec)
          debug("Execute: #{[method, args]}@#{receiver}/#{level}|async", highlight: true) if DEBUG_INJECTIONS
          receiver.async(method, *args)
        }
        true
      rescue => ex
        caught(ex, "Trouble setting [#{level}] executive.")
        false
      end
    end
  end
end

