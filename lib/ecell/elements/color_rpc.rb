require 'ecell/run'

require 'ecell/elements/color'

class ECell::Elements::Color
  def executable
    dump!(LOG_LINE)
    dump!("Piece: #{ECell::Run.piece_id} #{@data}")
    _ = @data.fetch(:args, [])
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
    RETURN_FORMS.each { |form|
      define_method(:"#{form}!") { |rpc, value, add={}|
        rpc.to = rpc.id
        rpc.id = ECell::Run.piece_id
        if value == :error
          rpc.error = add[:type] || :unknown
          rpc.code = :error
        else
          rpc[form] = value
        end
        rpc[:code] = form
        rpc[form] = value
        rpc.merge!(add) if add.any?
        rpc
      }
    }
  end
end

