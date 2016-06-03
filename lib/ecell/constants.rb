module ECell
  module Constants
    DEFAULT_LEADER    = :monitor
    DEFAULT_COURIER   = DEFAULT_LEADER

    DEBUG             = true
    DEBUG_DEEP        = false
    DEBUG_AUTOMATA    = false
    DEBUG_RESOURCES   = false #de Broken gem!
    DEBUG_SHUTDOWN    = false
    DEBUG_SERVICES    = true
    DEBUG_RELOADING   = false
    DEBUG_HTTP        = false
    DEBUG_SOCKET      = false
    DEBUG_INJECTIONS  = false
    DEBUG_EVENTS      = true
    DEBUG_RPCS        = false
    DEBUG_BACKTRACING = true

    CODE_RELOADING    = false
    CODE_PRYING       = true

    #benzrf TODO: replace with color names
    RETURN_COLORS = [
      :answer,
      :reply,
      :report,
      :failure
    ]

    COLORS = [
      :presence,
      :assertion,
      :call,
      :error,
      :operation,
      :log
    ] + RETURN_COLORS


    CONSOLE_TIME_FORMAT = '%T.%L' #de This is a fairly globalized format.

    LOG_STORAGE = :database

    LOG_LEVELS = [
      :debug,
      :info,
      :warn,
      :error
    ]

    LOG_FILE = {
      console: File.expand_path("../../logs/console.log", __FILE__),
      errors: File.expand_path("../../logs/error.log", __FILE__)
    }

    INJECTION_LAYERS = [
      :emitters,
      :relayers,
      :events,
      :executive_sync,
      :executive_async
    ]

    LINGER = 0

    DEFAULTS = {
      log_declare: true
    }

    INTERVALS = {
      margin: 0.222,
      before_oversight: 3,
      wait_transmission: 3,
      wait_events_cycle: 3,
      wait_tasks_cycle: 3,
      calling_timeout: 4,
      assertion_timeout: 4,
      reprovision_channel: 3,
      allow_transition: 1.26,
      ping: 5,
      check: 20,
      report: 45,
      heartbeat: 7,
      presence_announce: 1,
      second_chance: 3,
      third_chance: 5,
      restarting: 9,
      pageload: 6,
      retry_attach: 2,
      retry_ready: 1.26,
      announce_state: 9,
      waiting_leader: 1.26,
      audit_threads: 90,
      max_graceful: 9,
      client_inactivity: 60*10
    }

    VITALITY = {
      max_threads: 90
    }

    SERVICE_STATES = [
      :start,
      :attaching,
      :ready,
      :active,
      :running,
      :stalled,
      :waiting,
      :shutdown,
      :offline,
      :restarting
    ]

    #de Bindings & Interfaces could be loaded from a yml configuration file.

    DEFAULT_INTERFACE = "127.0.0.1"
    DEFAULT_PORT = 0

    MAX_SERVICE_FAILURES = 5
    MAX_SERVICE_TIMEOUTS = 3

    STROKES = [
      :logging_push,
      :logging_pull,

      :assertion_request,
      :assertion_reply,
      :assertion_router,
      :assertion_dealer,
      :assertion_publish,
      :assertion_subscribe,

      :presence_publish,
      :presence_subscribe,

      :calling_request,
      :calling_reply,
      :calling_router,
      :answering_router,

      :coordinator_pull,
      :operative_push,
      :operative_pull
    ]

    SERVICES = {
=begin
    hostmaster: {
      interface: DEFAULT_INTERFACE,
      roles: [:admin]
    },
=end
      monitor: {
        interface: DEFAULT_INTERFACE,
        designs: [:leader, :courier],
        members: [:process, :webstack]
      },
      process: {
        interface: DEFAULT_INTERFACE,
        designs: [:manager, :respondent],
        members: [:tasks, :events]
      },
      webstack: {
        interface: DEFAULT_INTERFACE,
        designs: [:member, :petitioner]
      },
      events: {
        interface: DEFAULT_INTERFACE,
        designs: [:member],
        leader: :process
      },
      tasks: {
        interface: DEFAULT_INTERFACE,
        designs: [:member],
        leader: :process
      }
    }

    #de Uses port 0 binding for everything except the presence channels...
    #de unless a port is set.

    WEBSTACK = {
      host: '0.0.0.0',
      port: 4567,
      threads: {
        min: 0,
        max: 16
      }
    }

    monitor_base = 7000
    process_base = 9000

    BINDINGS = {
      monitor: {
        presence_subscribe: monitor_base,
        logging_pull: monitor_base += 1,
        assertion_router: monitor_base += 1,
        assertion_publish: monitor_base += 1,
        answering_router: monitor_base += 1,
        calling_router: monitor_base += 1
      },
      process: {
        presence_subscribe: process_base,
        logging_pull: process_base += 1,
        coordinator_pull: process_base += 1,
        coordinator_tasks_push: process_base += 1,
        coordinator_events_push: process_base += 1,
        assertion_router: process_base += 1,
        assertion_publish: process_base += 1,
      },
      #de monitor: { presence_subscribe: 'monitor.presence', },
      #de process: { presence_subscribe: 'process.presence' },
      webstack: { http_server: WEBSTACK[:port] }
    }

    LINE = "< -- = --- = ---- = ----- = ------ = ---+--- = ------ = ----- = ---- = --- = -- > "

    CONSOLE_SYMBOLS = {
      marked: '#'.freeze,
      sent: '-'.freeze,
      relayed: '>'.freeze,
      timeout: '%'.freeze,
      error: '!'.freeze,
      code_reload: '~'.freeze,
      sent_log: '<'.freeze,
      sent_pong: '&'.freeze,
      got_pong: '@'.freeze,
      got_member: '+'.freeze,
      got_leader: '='.freeze,
      got_logging: '\\'.freeze,
      got_assertion: '$'.freeze,
      got_presencing: '/'.freeze,
      present_heartbeat: '^'.freeze,
      present_announcement: '*'.freeze,
      touched_work: '`'.freeze,
    }

    CONSOLE_SYMBOLS_KEY = CONSOLE_SYMBOLS.values.join("")
  end
end

