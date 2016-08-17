# Writing Shapes

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
    shape: Pester
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

