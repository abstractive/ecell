require 'json'
require 'colorize'
require 'celluloid/current'
require 'ecell/elements/figure'
require 'ecell/extensions'

#benzrf TODO: clean up the bizarre dependency hacks
# between this and files in `logging/`

module ECell
  module Base
    module Shapes
      class Logging < ECell::Elements::Figure
        def initialize(options)
          super(options)
          @storage = ECell.sync(:logging_storage)
          debug(message: "Initialized", reporter: self.class) if DEBUG_DEEP
        end

        #de TODO: Only necessary for pure Leader services, not even Managers.
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

        require 'ecell/base/shapes/logging/methods'

        ECell::Logger = self

        require 'ecell/base/shapes/logging/entry'

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
          ECell::Logger.log(options)
        rescue => ex
          ECell::Logger.caught(ex, "Failure to log a #{options.class.name} on the instance level:", store: options)
        end

        #benzrf there would be a `Collate`, but it turns out
        # there doesn't actually need to be

        module Document
          include ECell::Extensions

          def logging_root(piece_id)
            "tcp://#{PIECES[piece_id][:interface]}:#{BINDINGS[piece_id][:logging_pull]}"
          end

          def connect_logging!
            logging_push.connect = logging_root(leader)
            logging_push.online! if logging_push.engaged?
            symbol!(:got_logging)
          end
        end
      end
    end
  end
end

