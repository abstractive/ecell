module ECell
  module Constants
    DEFAULT_LEADER    = :monitor
    DEFAULT_COURIER   = DEFAULT_LEADER

    DEBUG             = true
    DEBUG_DEEP        = false
    DEBUG_AUTOMATA    = false
    DEBUG_RESOURCES   = false #de Broken gem!
    DEBUG_SHUTDOWN    = false
    DEBUG_PIECES      = true
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
    RETURN_FORMS = [
      :answer,
      :reply,
      :report,
      :failure
    ]

    COLOR_FORMS = [
      :announcement,
      :instruction,
      :call,
      :error,
      :task,
      :log
    ] + RETURN_FORMS

    RETURNS = {
      call: :answer,
      instruction: :reply,
      task: :report,
    }


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
      call_timeout: 4,
      instruction_timeout: 4,
      reprovision_line: 3,
      allow_transition: 1.26,
      ping: 5,
      check: 20,
      report: 45,
      heartbeat: 7,
      presence: 1,
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

    PIECE_STATES = [
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

    MAX_PIECE_FAILURES = 5
    MAX_PIECE_TIMEOUTS = 3

    # also used as Stroke ids
    LINE_IDS = [
      :logging_push,
      :logging_pull,

      :management_request,
      :management_reply,
      :management_router,
      :management_dealer,
      :management_publish,
      :management_subscribe,

      :awareness_publish,
      :awareness_subscribe,

      :calling_request,
      :calling_reply,
      :calling_router,
      :calling_router2,

      :distribution_push,
      :distribution_pull,
      :distribution_pull2,
    ]

    PIECES = {
=begin
    hostmaster: {
      interface: DEFAULT_INTERFACE,
      designs: [:admin]
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

    #de Uses port 0 binding for everything except the awareness lines...
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
        awareness_subscribe: monitor_base,
        logging_pull: monitor_base += 1,
        management_router: monitor_base += 1,
        management_publish: monitor_base += 1,
        calling_router2: monitor_base += 1,
        calling_router: monitor_base += 1
      },
      process: {
        awareness_subscribe: process_base,
        logging_pull: process_base += 1,
        distribution_pull2: process_base += 1,
        distribution_tasks_push2: process_base += 1,
        distribution_events_push2: process_base += 1,
        management_router: process_base += 1,
        management_publish: process_base += 1,
      },
      #de monitor: { awareness_subscribe: 'monitor.awareness', },
      #de process: { awareness_subscribe: 'process.awareness' },
      webstack: { http_server: WEBSTACK[:port] }
    }

    LOG_LINE = "< -- = --- = ---- = ----- = ------ = ---+--- = ------ = ----- = ---- = --- = -- > "

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
      got_instruction: '$'.freeze,
      got_announcing: '/'.freeze,
      announcing_heartbeat: '^'.freeze,
      announcing_presence: '*'.freeze,
      touched_work: '`'.freeze,
    }

    CONSOLE_SYMBOLS_KEY = CONSOLE_SYMBOLS.values.join("")
  end
end

