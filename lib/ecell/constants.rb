module ECell
  module Constants
    DEBUG             = true
    DEBUG_DEEP        = false
    DEBUG_AUTOMATA    = true
    DEBUG_RESOURCES   = false #de Broken gem!
    DEBUG_SHUTDOWN    = false
    DEBUG_PIECES      = true
    DEBUG_RELOADING   = false
    DEBUG_HTTP        = false
    DEBUG_SOCKET      = false
    DEBUG_EVENTS      = false
    DEBUG_RPCS        = false
    DEBUG_BACKTRACING = true

    CODE_RELOADING    = false
    CODE_PRYING       = true

    RETURNS = {
      call: [:calling, :answer],
      instruction: [:management, :reply],
      task: [:distribution, :report],
    }


    CONSOLE_TIME_FORMAT = '%T.%L' #de This is a fairly globalized format.

    LOG_STORAGE = :database

    LOG_LEVELS = [
      :debug,
      :info,
      :warn,
      :error
    ]

    DEFAULT_LOG_DIR = File.expand_path("../../../logs", __FILE__)

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

    #de Bindings & Interfaces could be loaded from a yml configuration file.

    DEFAULT_INTERFACE = "127.0.0.1"
    DEFAULT_PORT = 0

    MAX_PIECE_FAILURES = 5
    MAX_PIECE_TIMEOUTS = 3

    #de Uses port 0 binding for everything except the awareness lines...
    #de unless a port is set.

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
      got_follower: '+'.freeze,
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

