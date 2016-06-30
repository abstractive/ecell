require 'ecell/constants'

default = ECell::Constants::DEFAULT_INTERFACE
monitor_base = 7000
process_base = 9000

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
  process: {
    interface: default,
    awareness_subscribe: process_base,
    logging_pull: process_base += 1,
    distribution_pull2: process_base += 1,
    distribution_tasks_push2: process_base += 1,
    distribution_events_push2: process_base += 1,
    management_router: process_base += 1,
    management_publish: process_base += 1,
  },
  webstack: {
    interface: default,
    http_server: 4567
  }
}

DEMO_MESH_HIERARCHY = {
=begin
    hostmaster: {
      leader: :monitor,
    },
=end
  monitor: {
    leader: :monitor,
    followers: [:process, :webstack]
  },
  process: {
    leader: :monitor,
    followers: [:tasks, :events]
  },
  webstack: {
    leader: :monitor,
  },
  events: {
    leader: :process
  },
  tasks: {
    leader: :process
  }
}

