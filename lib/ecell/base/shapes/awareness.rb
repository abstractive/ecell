require 'colorize'
require 'ecell/elements/figure'
require 'ecell/extensions'
require 'ecell/run'
require 'ecell'

module ECell
  module Base
    module Shapes
      class Awareness < ECell::Elements::Figure
        lines :awareness_publish,
              :awareness_subscribe,

        def awareness_root(piece_id)
          "tcp://#{bindings[piece_id][:interface]}:#{bindings[piece_id][:awareness_subscribe]}"
        end

        module Notice
          include ECell::Extensions

          def on_announcement(data)
            missing = []
            missing << "piece id" unless data.id?
            missing << "color form" unless data.form?
            raise "No #{missing.join(' or ')}." unless missing.empty?
            case data.announcement
            when :presence
              ECell.async(:vitality).follower_attach(data)
            when :heartbeat
              ECell.async(:vitality).heartbeat!(data.id) if ECell.sync(:vitality).follower?(data.id)
            else
              debug("on_announcement[#{data.announcement}]: #{data}", reporter: self.class) if DEBUG_INJECTIONS
            end
          rescue => ex
            caught(ex, "Failure in on_announcement")
          end
        end

        module Announce
          include ECell::Extensions

          def connect_awareness!
            awareness_publish.connect = awareness_root(leader)
            awareness_publish.online! if awareness_publish.engaged?
            symbol!(:got_announcing)
          rescue => ex
            caught(ex, "Trouble connecting to awareness root.")
          end

          def announce_heartbeat!
            @heartbeating.cancel rescue nil
            debug(message: "Heartbeating.", reporter: self.class, banner: true) if DEBUG_DEEP
            symbol!(:announcing_heartbeat)
            awareness_publish << new_data.announcement(:heartbeat)
            @heartbeating = after(INTERVALS[:heartbeat]-INTERVALS[:margin]) { announce_heartbeat! }
          end

          def announce_presence!
            @presencing.cancel rescue nil
            return if ECell.sync(:management).attached?
            awareness_publish << new_data.announcement(:presence)
            symbol!(:announcing_presence)
            @presencing = after(INTERVALS[:presence]) { announce_presence! }
          rescue => ex
            caught(ex, "Trouble publishing to awareness root.")
          end
        end
      end
    end
  end
end

