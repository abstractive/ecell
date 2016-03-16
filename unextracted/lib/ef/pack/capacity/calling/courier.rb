module Ef::Pack::Capacity::Calling::Courier
  include Ef::Pack::Extensions

  def from_petitioner(rpc)
    console({
      reporter: 'Courier',
      message: "Call[#{rpc.id}/#{rpc.call}@#{rpc.to}]: #{rpc.uuid}",
      store: rpc,
      quiet: true
    })
    calling_router << rpc
  rescue => ex
    caught(ex, "Trouble handling call transaction from petitioner.")
    calling_router << exception!(ex)
  end

  def from_respondent(rpc)
    if rpc.success?
      console({
        reporter: 'Courier',
        message: "Answer: #{rpc.id}/#{rpc.call}@#{rpc.to}]: #{rpc.answer}",
        store: rpc,
        quiet: true
      })
    else
      log_warn({
        reporter: 'Courier',
        message: "Failure: #{rpc.id}/#{rpc.call}]: #{rpc.error}",
        store: rpc,
        quiet: true
      })
    end
    answering_router << rpc
  rescue => ex
    caught(ex, "Trouble handling call transaction from respondent")
    begin
      answering_router << exception!(ex, call: rpc.call, store: rpc)
    rescue => ex
      caught(ex, "Could not recover response.")
    end
  end

end
