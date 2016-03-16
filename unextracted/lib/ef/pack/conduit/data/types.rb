Ef::Data = Ef::Pack::Conduit::Data

class Ef::Pack::Conduit::Data
  class << self
    include Ef::Constants
    
    def [](data)
      new(data)
    end
    def []=(socket,data)
      socket << new(data).packed
    end
    def exception!(ex)
      Ef::Data.error!(:exception, exception: ex)
    end

    DATA_TYPES.each { |type|
      next if RETURN_TYPES.include?(type)
      typed = type.to_s.capitalize.to_sym
      define_method(:"#{type}!") { |value, data={}|
        Ef[:logging].debug({
          message: "Data object... #{typed}: #{value}",
          report: self.class
        }) if DEBUG_DEEP
        const_get(typed).new(value, data)
      }
      handler = Module.new
      handler.define_singleton_method(:[]) { |value| new(value) }
      handler.define_singleton_method(:new) { |value, extras={}|
        Ef::Pack::Conduit::Data.new(extras.merge({code: type, type => value}))
      }
      Ef::Pack::Conduit::Data.const_set(typed, handler)
    }
  end
end
