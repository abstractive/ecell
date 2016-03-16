module Ef::Pack
  class << self

    include Ef::Pack::Extensions

    def filtered_hash(current, exclude)
      return current unless exclude
      current.inject({}) { |hash,(branch,entities)|
        hash[branch] = (!exclude.key?(branch)) ? entities : filtered_array(entities, exclude[branch]); hash 
      }
    end

    def filtered_array(current, exclude)
      current.select { |entity| !exclude.include?(entity) }
    end

    def Default(spec)
      spec = {roles: spec}
      combined, roles = {}, spec.delete(:roles) || spec.delete(:merge)
      roles << spec if spec.any?
      roles, without = expand_defaults(roles)
      roles.each { |defaults|
        INJECTION_LAYERS.each { |layer|
          if defaults[layer].is_a?(Hash)
            if !combined.key?(layer)
              combined[layer] = unless without.is_a?(Hash)
                defaults[layer]
              else
                filtered_hash(defaults[layer], without[layer])
              end
            else
              defaults[layer].each { |branch, entities|
                array = if without && without[layer].is_a?(Hash) && without[layer][branch].is_a?(Array)
                  filtered_array(entities, without[layer][branch])
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
          elsif !defaults[layer].nil?
            fail("Hash>Hash or Hash>Array expected. Got Hash>#{defaults[layer].class.name}")
          end
        }
      }
      combined
    end

    def expand_defaults(roles)
      defaults, without = [], {}
      roles.each { |r|
        r = r.Defaults unless r.is_a?(Hash)
        embedded = r.delete(:roles) || r.delete(:merge)
        if embedded.is_a?(Array)
          defaults += embedded.map { |e| (e.is_a?(Hash)) ? e : e.Defaults }
        end
        defaults.push(r)
      }
      defaults.each { |d|        
        w = (scope = d[:scope]) && scope.respond_to?(:Without) && scope.Without
        without.merge!(w) if w.is_a?(Hash)
      }
      [defaults, without]
    end
  end
end
