# Basic Usage

## Running Pieces

To run a Piece, first instantiate `ECell::Runner`, then call the `run!` method
with a configuration hash. This is blocking.

```ruby
require 'ecell/runner'
runner = ECell::Runner.new
runner.run!(configuration)
```

You can shut down the Piece by calling the `Runner`'s `shutdown` method.

The most important configuration hash keys are:
* `:piece_id`: The ID of the Piece. This should be unique within a mesh.
* `:designs`: A list of Designs to use. This specifies the bulk of the Piece's
  actual logic and functionality.
* `:log_dir`: The directory to store log files in.
* `:bindings`: The preset bindings that Pieces in the mesh are expected to
  make. This is used by the Piece both to find other Pieces and to make its own
  bindings, if any. It takes the form of a nested hash: The keys of the first
  hash are Piece IDs, and each value hash maps binding IDs (usually Line IDs)
  to ports. Value hashes also have an `:interface` key, indicating the
  interface that the Piece is bound to. An example value for `:bindings`:

  ```ruby
  default = ECell::Constants::DEFAULT_INTERFACE
  monitor_base = 7000

  DEMO_MESH_BINDINGS = {
    monitor: {
      interface: default,
      awareness_subscribe: monitor_base,
      logging_pull: monitor_base += 1,
      management_router: monitor_base += 1,
      management_publish: monitor_base += 1,
      calling_router2: monitor_base += 1,
      calling_router: monitor_base += 1
    },
    reel_static: {
      interface: "0.0.0.0",
      http_server: 4567
    }
  }
  ```

The configuration hash is globally available, though, so each Shape may have
its own expected keys.

## Writing Designs
Each Design takes the form of a list of specifications for Figures. Each
specification should be a hash with the following keys:

* `:as`: (Symbol) What to supervise the Figure as.
* `:type`: (Class) The Shape of the Figure.
* `:faces`: (Array<Symbol>) (optional) A list of Face names to include in the
  Figure (in lowercase).
* `:strokes`: (Hash<Symbol, Hash>) (optional) Some specifications for Lines to
  provide the Figure with. The keys are line IDs (doubling as stroke IDs to
  look up in `ECell::Autoload::Strokes`); the value a key maps to should be an
  options hash to pass to initialize the Line with. The example below assumes
  the existence of something like this:

  ```ruby
  module ECell::Autoload::Strokes
    module Hypothetical
      class Connector < ECell::Elements::Line
        # ...
      end
    end
  end
  ```

Here's an example:

```ruby
ExampleDesign = [
  {
    as: :foo,
    type: Hypothetical,
    faces: [:some, :faces],
    strokes: {
      hypothetical_connector: {mode: :connecting}
    }
  }
]
```

## Writing Shapes

This section will focus only on writing non-general-purpose Shapes that
implement Piece-specific functionality.

First, subclass `ECell::Elements::Figure`. If you need to override
`initialize`, make sure to take the arguments `frame`, `faces`, and `strokes`,
and to call `super`. *Don't* use `initialize` to do nontrivial setup, though.

```ruby
require 'ecell/elements/figure'

class Pester < ECell::Elements::Figure
  def initialize(frame, faces, strokes)
    super
    # some kind of setup here
  end
end
```

Next, write an event handler to run your setup code when the `started` event
occurs (this will be right after all of the Figures and Lines have been
provisioned).

```ruby
require 'ecell/elements/figure'

class Pester < ECell::Elements::Figure
  def initialize(frame, faces, strokes)
    super
    # some kind of setup here
  end

  def on_started
    every(5) do
      # Pester another Piece here
    end
  end
end
```

When the `foo` event occurs, every `on_foo` handler will be called on every
Figure in the Piece. Importantly, this includes every `on_foo` method in each
Figure's ancestors chain, so it's okay to write handlers in multiple ancestors
of a Shape without using `super`.

Finally, you can make use of other Figures by just calling methods on them.

```ruby
require 'ecell'
require 'ecell/elements/figure'

class Pester < ECell::Elements::Figure
  def initialize(frame, faces, strokes)
    super
    # some kind of setup here
  end

  def on_started
    every(5) do
      # `ECell.sync` is an alias to `Celluloid::Actor.[]`.
      # The `call_async` method on the `Calling` Figure is used to make
      # async RPCs. We're assuming that `:other_piece` supports a `poke`
      # RPC.
      ECell.sync(:calling).call_async(:other_piece).poke
    end
  end
end
```

You can use this Figure in a Piece by just adding the following Design to the
list:

```ruby
PesterDesign = [
  {
    as: :pester,
    type: Pester
  }
]
```

Of course, you'd need to make sure that you're also using a Design that
provides the `Calling` Figure with the `Call` face.

## Using `ECell::Extensions`

The `ECell::Extensions` module provides several useful convenience methods,
including logging methods and a configuration accessor. It's already included
in many of the basic ECell classes (including `Figure`), but it may also be
useful to include into your own classes. Most of the methods expect `@frame` to
be set to a Frame, so be sure to assign it in `initialize` for any classes you
use it in. See the Reel Piece in `examples/` for an example.

