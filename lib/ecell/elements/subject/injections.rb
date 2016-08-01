require 'celluloid/current'
require 'ecell/internals/actor'
require 'ecell'
require 'ecell/extensions'

module ECell
  module Elements
    class Subject < ECell::Internals::Actor
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

