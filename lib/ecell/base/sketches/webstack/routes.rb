require 'sinatra'
require 'time'
require 'ecell/run'
require 'ecell'
require 'ecell/base/shapes/calling'
require 'ecell/elements/color'

require 'ecell/base/sketches/webstack/shape'

class ECell::Base::Sketches::WebstackShape::Routes < Sinatra::Base
  set :server, :puma
  set :static, true
  set :public_folder, ECell::Base::Sketches::WebstackShape::PUBLIC_ROOT

  get('/') {
    break redirect('/loading') unless ECell.sync(:management).follower_state?(:running)
    redirect("/index.html")
  }

  get('/rpc') {
    break redirect('/loading') unless ECell.sync(:management).follower_state?(:running)
    redirect("/rpc.html")
  }

  get('/loading') {
    redirect("/loading.html")
  }

  get('/trigger') {
    response = nil
    begin
      ECell.sync(:ClientRegistry).clients_announce!("Making RPC to :process piece. Waiting for reply...")
      ECell.sync(:calling).call_sync(:process).web_trigger(rpc: {message: "RPC #{Time.now.iso8601}"}) { |rpc|
        if rpc.success?
          ECell.sync(:ClientRegistry).clients_announce!("#{rpc.id}[#{rpc.answer}] #{rpc.message}.")
          ECell.async(:logging).debug("Ran web_trigger.", store: rpc, quiet: true)
        else
          message = if rpc.message?
            "#{rpc.id}[#{rpc.error}] #{rpc.message}."
          elsif rpc[:exception]
            "#{rpc.id}[#{rpc[:exception][:type]}] #{rpc[:exception][:message]}."
          else
            "There was an unknown error. Sorry about that."
          end
          ECell.sync(:ClientRegistry).clients_announce!(message)
        end
        response = rpc
      }
    rescue => ex
      response = ECell::Elements::Color::Instantiator[:self].error(:exception, exception: ex)
    end
    unless response.success?
      if response[:exception]
        "Failure running web trigger.\n\nException: #{response[:exception][:message]}\n(#{response[:exception][:type]})"
      else
        "Error received piece: #{response[:error]}\nFrom: #{response.id}"
      end
    else
      response.message
    end
  }

  get('/list/:type') {
    response = nil
    begin
      ECell.sync(:ClientRegistry).clients_announce!("Requested list of #{params[:type]}. Waiting for reply...")
      ECell.sync(:calling).call_sync(:process).get_list(params[:type], :indiscriminate_demonstration) { |rpc|
        if rpc.success?
          ECell.sync(:ClientRegistry).clients_announce!("List of mock #{params[:type]}:")
          rpc.returns[:"#{params[:type]}"].each { |item|
            output = item.inject([]) { |string,(key, value)| string << "#{key}:#{value}"}
            ECell.sync(:ClientRegistry).clients_announce!("#{output.join(', ')}.")
          }
          ECell.async(:logging).debug("Got #{params[:type]}.", store: rpc, quiet: true)
        else
          message = if rpc.message?
            "#{rpc.id}[#{rpc.error}] #{rpc.message}."
          elsif rpc[:exception]
            "#{rpc.id}[#{rpc[:exception][:type]}] #{rpc[:exception][:message]}."
          else
            "There was an unknown error. Sorry about that."
          end
          ECell.sync(:ClientRegistry).clients_announce!(message)
        end
        response = rpc
      }
    rescue => ex
      response = ECell::Elements::Color::Instantiator[:self].error(:exception, exception: ex)
    end
    unless response.success?
      if response[:exception]
        "Failure running web trigger.\n\nException: #{response[:exception][:message]}\n(#{response[:exception][:type]})"
      else
        "Error received piece: #{response[:error]}\nFrom: #{response.id}"
      end
    else
      "See the WebSocket console for a listing which could have been rendered as JSON and returned instead."
    end
  }
end

