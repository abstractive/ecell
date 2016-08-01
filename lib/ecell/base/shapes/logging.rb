require 'json'
require 'colorize'
require 'celluloid/current'
require 'ecell/elements/figure'
require 'ecell/internals/logger'
require 'ecell/constants'

#benzrf TODO: clean up the bizarre dependency hacks
# between this and files in `logging/`

module ECell
  module Base
    module Shapes
      class Logging < ECell::Elements::Figure
        lines :logging_push,
              :logging_pull

        include ECell::Internals::Logger

        def initialize(options)
          super(options)
          @storage = ECell.sync(:logging_storage)
          debug(message: "Initialized", reporter: self.class) if DEBUG_DEEP
        end

        #de TODO: Only necessary for pure Leader pieces, not even Managers.
        STORAGE = case ECell::Constants::LOG_STORAGE
        when :file
          require 'ecell/base/shapes/logging/file'
          File
        when :database
          require 'ecell/base/shapes/logging/database'
          Database
        else
          raise "No valid log storage mode specified."
        end

        def log(options)
          entry = log_entry(options)
          unless entry.local?
            if logging_push?
              symbol!(:sent_log)
              return logging_push << entry
            end
          end
          display(entry)
          save(entry)
        rescue Celluloid::TaskTerminated
          ECell::Internals::Logger.log(options)
        rescue => ex
          ECell::Internals::Logger.caught(ex, "Failure to log a #{options.class.name} on the instance level:", store: options)
        end

        module Collate
          def on_started
            emitter logging_pull, :log
          end
        end

        module Document
          def on_started
            connect_logging!
          end

          def logging_root(piece_id)
            "tcp://#{bindings[piece_id][:interface]}:#{bindings[piece_id][:logging_pull]}"
          end

          def connect_logging!
            logging_push.connect = logging_root(leader)
            logging_push.online! if logging_push.engaged?
            symbol!(:got_logging)
          end
        end

        module Relay
          def on_setting_up
            async.relayer logging_pull, logging_push
          end
        end
      end
    end
  end
end

