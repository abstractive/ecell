require 'ecell/elements/subject'
require 'ecell/base/designs/follower'
require 'ecell/base/designs/caller'
require 'ecell/base/designs/answerer'
require 'ecell/base/sketches/webstack/extensions'

module ECell
  module Base
    module Sketches
      class Webstack < ECell::Elements::Subject
        PUBLIC_ROOT = File.expand_path("../../../../../public", __FILE__)

        def initialize(configuration={})
          #benzrf TODO: fix infinite-recursion bug due to `Extensions`-defined
          # methods overriding the things they delegate to. Until then,
          # do *not* swap the order of `Answerer` and `Caller` below.
          design! ECell::Base::Designs::Follower,
                  ECell::Base::Designs::Answerer,
                  ECell::Base::Designs::Caller
          super(configuration)
        rescue => ex
          raise exception(ex, "Failure initializing.")
        end

        module RPC
          include ECell::Base::Sketches::Webstack::Extensions

          def announcement(rpc, *args)
            dump!(args)
            message = rpc.delete(:message)
            timestamp = rpc.delete(:timestamp)
            tag = rpc.delete(:tag)
            return error!(:missing_message) unless message
            message = "[#{tag}] #{message}" if tag
            message += " #{Time.at(timestamp)}" if timestamp
            clients_announce!("#{rpc.id}#{message}", rpc.topic)
            answer!(rpc, :ok)
          end

          def welcome!(member)
            if super
              clients_announce!("[ #{member} ] Connected")
            end
          end
        end

        include RPC
      end
    end
  end
end

require 'ecell/base/sketches/webstack/automaton_hooks'

