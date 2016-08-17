# Running Pieces

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

