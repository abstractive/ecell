require 'ecell/internals/actor'

module ECell
  module Elements
    class Subject < ECell::Internals::Actor
      def system_check!
        console(tag: 'system check', message: "Intervention triggered.", highlight: true)
        threads = Thread.list.inject({}) { |l,t| l[t.object_id] = t.status; l }
        {
          threads: {
            total: threads.count,
            running: threads.select { |id,status| status == 'run' }.count,
            sleeping: threads.select { |id,status| status == 'sleep' }.count,
            aborted: threads.select { |id,status| status == 'aborting' }.count,
            terminated: {
              normally: threads.select { |id,status| status === false }.count,
              exception: threads.select { |id,status| status.nil? }.count
            }
          },
          memory: :os_dependent #de Code I have for this is *nix only right now.
        }
      end

      def restart_piece!
        console(tag: 'hard reset', message: "Intervention triggered.", highlight: true)
      end

      def hard_reset!
        console(tag: 'hard reset', message: "Intervention triggered.", highlight: true)
      end

      def graceful_shutdown!
        console(tag: 'graceful shutdown', message: "Intervention triggered.", highlight: true)
      end

      def hibernate!
        console(tag: 'hibernate', message: "Intervention triggered.", highlight: true)
      end

      def wake_up!
        console(tag: 'wake up', message: "Intervention triggered.", highlight: true)
      end
    end
  end
end

