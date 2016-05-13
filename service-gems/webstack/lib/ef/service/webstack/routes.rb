class Ef::Service::Webstack::Routes < Sinatra::Base

  set :server, :puma
  set :static, true
  set :public_folder, Ef::Service::Webstack::PUBLIC_ROOT

  get('/') {
    break redirect('/loading') unless Ef::Service.current.state?(:running)
    redirect("/index.html")
  }

  get('/restful') {
    break redirect('/loading') unless Ef::Service.current.state?(:running)
    redirect("/restful.html")
  }

  get('/loading') {
    redirect("/loading.html")
  }

  get('/trigger') {
    response = nil
    begin
      Ef::Actor[:ClientRegistry].clients_announce!("Making RPC to :process service. Waiting for reply...")
      Ef::Call[:process].restful_trigger(rpc: {message: "RPC #{Time.now.iso8601}"}) { |rpc|
        if rpc.success?
          Ef::Actor[:ClientRegistry].clients_announce!("#{rpc.id}[#{rpc.answer}] #{rpc.message}.")
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
    rescue => ex
      response = Ef::Data.exception!(ex)
    end
    unless response.success?
      if response[:exception]
        "Failure running RESTful trigger.\n\nException: #{response[:exception][:message]}\n(#{response[:exception][:type]})"
      else
        "Error received service: #{response[:error]}\nFrom: #{response.id}"
      end
    else
      response.message
    end
  }

  get('/list/:type') {
    response = nil
    begin
      Ef::Actor[:ClientRegistry].clients_announce!("Requested list of #{params[:type]}. Waiting for reply...")
      Ef::Call[:process].get_list(params[:type], :indiscriminate_demonstration) { |rpc|
        if rpc.success?
          Ef::Actor[:ClientRegistry].clients_announce!("List of mock #{params[:type]}:")
          rpc[:"#{params[:type]}"].each { |item|
            output = item.inject([]) { |string,(key, value)| string << "#{key}:#{value}"}
            Ef::Actor[:ClientRegistry].clients_announce!("#{output.join(', ')}.")
          }
          Ef[:logging].debug("Got #{params[:type]}.", store: rpc, quiet: true)
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
    rescue => ex
      response = Ef::Data.exception!(ex)
    end
    unless response.success?
      if response[:exception]
        "Failure running RESTful trigger.\n\nException: #{response[:exception][:message]}\n(#{response[:exception][:type]})"
      else
        "Error received service: #{response[:error]}\nFrom: #{response.id}"
      end
    else
      "See the WebSocket console for a listing which could have been rendered as JSON and returned instead."
    end
  }

end
