# Extending ECell

## Strokes

To make your own Stroke, just subclass `Line`. `initialize` should take one
argument (`options`), set `@socket` to the socket you're going to use, and then
call `super(self, options)`. In order for the autoloading mechanism to be able
to find it by the ID `shapename_strokename`, you should set
`ECell::Autoload::Strokes::Shapename::Strokename` to the stroke. Here's an
example of a Stroke that can be loaded as `awareness_subscribe`:

```ruby
module ECell::Autoload::Strokes
  module Awareness
    class Subscribe < ECell::Elements::Line
      def initialize(options={})
        @socket = Socket::Sub.new
        super(self, options)
        @socket.subscribe("")
      end
    end
  end
end
```

## General-Purpose Shapes

To make your own Shape, just subclass `Figure`. Each Face of the Shape should
be a module in the Shape. You can use the method `Figure.lines` to generate
shortcut methods for accessing the Lines that the Figure will use. Here's an
example:

```ruby
#benzrf TODO: test this code to make sure it actually works
class Storage < ECell::Elements::Figure
  lines :storage_req, :storage_rep, :storage_push, :storage_pull

  def initialize(frame, faces, strokes)
    super
    @stored = {}
  end

  module Store
    # assuming that the lines are provisioned in `:binding` mode, they will
    # automatically bind during provisioning using the information in the
    # configuration

    # runs at the `setting_up` event, which occurs once the Piece this is in
    # has attached to a leader
    def on_setting_up
      # call the `on_get` method whenever storage_rep gets a message
      emitter storage_rep, :on_get
      # call the `on_store` method whenever storage_pull gets a message
      emitter storage_pull, :on_store
    end

    def on_store(req)
      @stored[req.set] = req.value
    end

    def on_get(req)
      if @stored.include?(req.lookup)
        val = @stored[req.lookup]
        # use the `new_return` method from Extensions to construct a
        # return-value Color object
        storage_rep << new_return.lookup_result(req, val)
      else
        storage_rep << new_return.lookup_failure(:no_such_key)
      end
    end
  end

  module Query
    def url_for(piece_id, line_id)
      "tcp://#{bindings[piece_id][:interface]}:#{bindings[piece_id][line_id]}"
    end

    def on_setting_up
      storer_piece = configuration[:storer_piece]
      storage_req.connect = url_for(storer_piece, :storage_rep)
      storage_req.online! if storage_req.engaged?
      storage_push.connect = url_for(storer_piece, :storage_pull)
      storage_push.online! if storage_push.engaged?
    end

    def [](k)
      storage_req << new_data.lookup(k)
      storage_req.read_one
    end

    def []=(k, v)
      storage_push << new_data.set(k, value: v)
    end
  end
end
```

