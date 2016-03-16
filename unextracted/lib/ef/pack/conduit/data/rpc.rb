class Ef::Pack::Conduit::Data

  def executable
    dump!(LINE)
    dump!("Service: #{Ef::Service.identity} #{@data}")
    _ = @data.delete(:args) || []
    dump!("args: #{_}")
    params = [@data[@data[:code].to_sym]]
    if _.is_a?(Array)
      if _.any?
       dump!("Array has something in it.")
        if _.first == :rpc
          dump!("At the front it's :rpc")
          _[0] = self
        elsif _.first.is_a?(Hash)
          dump!("First is a Hash. Keys: #{_.first.keys}")
          if _.first.keys.one?
            dump!("Just one key.")
            if _.first[:rpc].is_a?(Hash)
              dump!("It calls for an RPC merger.")
              _ = [self.merge!(_[0][:rpc])]
            end
          end
        else
          debug("It's nothing special...")
        end
      end
      params += _
    end
    dump!("params: #{params}")
    params
  rescue => ex
    [:exception, ex, "Error in executable parser."]
  end

  class << self
    RETURN_TYPES.each { |type|
      define_method(:"#{type}!") { |rpc, value, add={}|
        rpc.to = rpc.id
        rpc.id = Ef::Service.identity
        if value == :error
          rpc.error = add[:type] || :unknown
          rpc.code = :error
        else
          rpc[type] = value
        end
        rpc[:code] = type
        rpc[type] = value
        rpc.merge!(add) if add.any?
        rpc
      }
    }
  end

end

if Ef::Service.identity?(:webstack)
  Ef::Call[:process].restful_trigger(rpc: {message: "RPC #{Time.now.iso8601}"}) { |rpc|
      if rpc.success?
        Ef::Actor[:ClientRegistry].clients_announce!("#{rpc.id}[#{rpc.code}] #{rpc.message}.")
        Ef[:logging].debug("Ran restful_trigger.", store: rpc, quiet: true)
      else
        message = if rpc.message?
          "#{rpc.id}[#{rpc.error}] #{rpc.message}."
        elsif rpc[:exception]
          "#{rpc.id}[#{rpc[:exception][:type]}] #{rpc[:exception][:message]}."
        else
          "There was an unknown error. Sorry about that."            
        end
        Ef::Actor[:ClientRegistry].clients_announce!(message)
      end
      response = rpc
    }

  Ef::Logger.dump! Ef::Call::Async[:process].restful_trigger(rpc: {message: "RPC.async #{Time.now.iso8601}"})
end

