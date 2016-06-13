require 'ecell/internals/actor'
require 'ecell/extensions'
require 'ecell/run'
require 'ecell/errors'
require 'ecell'
require 'ecell/constants'

module ECell
  module Elements
    class Figure < ECell::Internals::Actor
      include ECell::Extensions

      def initialize(options)
        @options = options
        @sockets = {}
      end

      def shutdown
        @sockets.inject([]) { |shutdown,(line,socket)|
          shutdown << socket.future.transition(:shutdown)
        }.map(&:value)
      end

      def relayer(from, to)
        debug(message: "Setting a relay from #{from}, to #{to}") if DEBUG_INJECTIONS
        if @sockets[to].ready?
          @sockets[from].reader { |data|
            @sockets[to] << data
          }
        end
      rescue => ex
        caught(ex, "Trouble with relayer.") if ECell::Run.online?
        return
      end

      LINE_IDS.each { |line_id|
        define_method(:"#{line_id}?") { @sockets[line_id] && @sockets[line_id].online }
        define_method(line_id) { |options={}| @sockets[line_id] || raise(ECell::Error::Line::Uninitialized) }
      }

      def initialize_line(line_id, options)
        @sockets[line_id] = super
      rescue => ex
        raise exception(ex, "Line Supervision Exception")
      end
    end
  end
end

#benzrf TODO: migrate these; also, find a better place for the requires
if false
require 'ecell/base/shapes/logger'
require 'ecell/base/shapes/spool'
#de require 'set'

ECell::Supervise(as: :spool, type: ECell::Base::Shapes::Spool)

#benzrf TODO: find grammatically-more-suited names for some of these
require 'ecell/base/shapes/presence'
require 'ecell/base/shapes/asserter'
require 'ecell/base/shapes/caller'
require 'ecell/base/shapes/operative'
require 'ecell/base/shapes/vitality'
require 'ecell/base/shapes/database'

#de TODO: Only necessary for pure Leader services, not even Managers.
ECell::Base::Shapes::Logger::STORAGE = case ECell::Constants::LOG_STORAGE
                                       when :file
                                         ECell::Base::Shapes::Logger::Storage::File
                                       when :database
                                         ECell::Base::Shapes::Logger::Storage::Database
                                       else
                                         raise "No log storage mode specified."
                                       end
end

