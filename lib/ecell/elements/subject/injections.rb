require 'celluloid/current'
require 'ecell/internals/actor'
require 'ecell'
require 'ecell/extensions'

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
      def emitter!(line_id, figure_id=nil, method)
        debug("Triggering emitter, #{method}@#{line_id}.") if DEBUG_INJECTIONS
        receiver = figure_id ? ECell.sync(figure_id) : Celluloid::Actor.current
        ECell.sync(line_id).async(:emitter, receiver, method)
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

      # Helper methods for processing Injections in Designs.
      module Injections
        class << self
          include ECell::Extensions

          def filtered_hash(current, exclude)
            return current unless exclude
            current.inject({}) { |hash,(branch,entities)|
              hash[branch] = (!exclude.key?(branch)) ? entities : filtered_array(entities, exclude[branch]); hash
            }
          end

          def filtered_array(current, exclude)
            current.select { |entity| !exclude.include?(entity) }
          end

          def injections_for(designs)
            combined = {}
            designs, disabled = expand_injections(designs)
            designs.each { |injections|
              INJECTION_LAYERS.each { |layer|
                if injections[layer].is_a?(Hash)
                  if !combined.key?(layer)
                    combined[layer] = unless disabled.is_a?(Hash)
                      injections[layer]
                    else
                      filtered_hash(injections[layer], disabled[layer])
                    end
                  else
                    injections[layer].each { |branch, entities|
                      array = if disabled && disabled[layer].is_a?(Hash) && disabled[layer][branch].is_a?(Array)
                        filtered_array(entities, disabled[layer][branch])
                      else
                        entities
                      end
                      if combined[layer].key?(branch)
                        combined[layer][branch] += array
                      else
                        combined[layer][branch] = array
                      end
                    }
                  end
                elsif !injections[layer].nil?
                  fail("Hash>Hash or Hash>Array expected. Got Hash>#{defaults[layer].class.name}")
                end
              }
            }
            combined
          end

          def expand_injections(designs)
            injections, disabled = [], {}
            designs.each { |r|
              r = r::Injections unless r.is_a?(Hash)
              embedded = r[:designs] || r[:merge]
              if embedded.is_a?(Array)
                injections += embedded.map { |e| e.is_a?(Hash) ? e : e::Injections }
              end
              injections.push(r)
            }
            injections.each { |i|
              d = (scope = i[:scope]) && scope.const_defined?(:Disabled) && scope::Disabled
              disabled.merge!(d) if d.is_a?(Hash)
            }
            [injections, disabled]
          end
        end
      end
    end
  end
end

