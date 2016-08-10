require 'ecell/constants'

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
    # just use the defaults
  }
}

DEMO_MESH_HIERARCHY = {
  monitor: {
    leader: :monitor,
    followers: [:reel_static]
  },
  reel_static: {
    leader: :monitor,
  },
}

