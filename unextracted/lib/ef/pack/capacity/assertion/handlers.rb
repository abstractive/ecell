module Ef::Pack::Capacity::Assertion::Handlers
  include Ef::Pack::Extensions

  def assertion_root(service)
    [
      "tcp://#{SERVICES[service][:interface]}:#{BINDINGS[service][:assertion_router]}",
      "tcp://#{SERVICES[service][:interface]}:#{BINDINGS[service][:assertion_publish]}"      
    ]
  end

  def connect_assertion!
    specific, general = *assertion_root(@leader)
    assertion_dealer.connect = specific
    assertion_subscribe.connect = general
    symbol!(:got_assertion)
  end

  def on_reply(rpc)
    symbol!(:marked)
    replying!(rpc.uuid, rpc)
  end

  def on_assertion(rpc)
    raise "No assertion." unless rpc.assertion?
    return assertion_dealer << case rpc.assertion
    when :ping!
      symbol!(:sent_pong)
      reply!(rpc, :pong)
    when :attach!
      reply!(rpc, :ok)
      if @attached
        log_warn("Already attached.")
        reply!(rpc, :ok)
      else
        symbol!(:got_leader)
        @attached = true
        async(:event!, :attaching, rpc)
        reply!(rpc, :ok)
      end
    else
      debug(tag: :assertion, message:"#{rpc.assertion}, args: #{rpc[:args]}", highlight: true) #de if DEBUG_DEEP
      symbol!(:got_assertion)
      if respond_to?(rpc.assertion)
        begin
          arity = method(rpc.assertion).arity
          if rpc.args?
            if rpc.args.is_a?(Array)
              if rpc.args.any? && arity == 0
                reply!(rpc, :error, type: :arity_mismatch)
              elsif rpc.args.length == arity || arity < 0
                reply!(rpc, :result, returns: send(rpc.assertion, *rpc.args))
              else
                reply!(rpc, :error, type: :unknown_arity_error)                    
              end
            else
              if arity == 1
                reply!(rpc, :result, returns: send(rpc.assertion, rpc.args))
              else
                reply!(rpc, :error, type: :arity_mismatch)
              end
            end
          elsif !rpc.args? && arity <= 0
            reply!(rpc, :result, returns: send(rpc.assertion))
          else
            reply!(rpc, :error, type: :unknown_error)      
          end
        rescue => ex
          reply!(rpc, :exception, exception: ex)
        end
      else
        debug(message: "Unknown Assertion: #{rpc.assertion}", banner: true)
        reply!(rpc, :error, type: :unknown_assertion)
      end
    end
  rescue => ex
    caught(ex, "Failure on assertion.")
    exception!(ex)
  end

end
