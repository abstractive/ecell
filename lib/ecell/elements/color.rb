require 'forwardable'
require 'msgpack'
require 'ecell'
require 'ecell/constants'
require 'ecell/extensions'
require 'ecell/run'

module ECell
  module Elements
    class Color
      class << self
        include ECell::Constants

        #benzrf TODO: revise the mostly-unnecessary dynamic module stuff here
        COLOR_FORMS.each { |form|
          next if RETURN_FORMS.include?(form)
          form_cap = form.to_s.capitalize.to_sym
          define_method(:"#{form}!") { |value, data={}|
            ECell.async(:logging).debug({
              message: "Color object... #{form_cap}: #{value}",
              report: self.class
            }) if DEBUG_DEEP
            const_get(form_cap).new(value, data)
          }
          handler = Module.new
          handler.define_singleton_method(:[]) { |value| new(value) }
          handler.define_singleton_method(:new) { |value, extras={}|
            #benzrf TODO: s/`code`/`form`/g
            Color.new(extras.merge({code: form, form => value}))
          }
          Color.const_set(form_cap, handler)
        }

        def [](data)
          new(data)
        end
        def []=(socket,data)
          socket << new(data).packed
        end
        def exception!(ex)
          error!(:exception, exception: ex)
        end
      end

      include ECell::Extensions
      extend Forwardable
      def_delegators :@data, :key?, :keys, :fetch, :delete

      def initialize(hash={})
        @data = (hash.respond_to? :export) ? hash.export : hash
        if @data.is_a?(Array)
          @data.select! { |element| !element.empty? }
          if @data.one?
            @data = @data[0]
          else
            raise ArgumentError, "Invalid message array: #{@data.length}"
          end
        end
        @packed = @data.is_a?(String)
        @data = unpacked!
        @data[:id] ||= ECell::Run.identity
        #de @data[:timestamp] ||= Time.now.to_f
        @data[:uuid] ||= uuid!
      rescue => ex
        caught(ex, "Failure instantiating Color")
        @data = {error: :corrupted, code: :error, exception: ex}
      end

      ([:id, :code] + COLOR_FORMS).each { |key|
        define_method(:"#{key}?") { |val=nil| !@data[key].nil? && (val.nil? || send(key) == val) }
        define_method(:"#{key}=") { |value| @data[key] = static_value(value) }
        define_method(key) { @data[key] && static_value(@data[key]) }
      }

      def static_value(value)
        return if value.nil?
        return value.to_sym if value.is_a?(String)
        value
      end

      def replied?(answer)
        reply == answer
      end

      #de We need this thunk,
      #de otherwise the interal hash is let out,
      #de and we lose the Color object.
      [:merge, :merge!].each { |m|
        define_method(m) { |h|
          raise ArgumentError unless h.is_a?(Color) || h.is_a?(Hash)
          unless h.is_a?(Hash)
            h = h.export
          end
          #benzrf TODO: should this be `:merge!` instead?
          log_warn("Not keeping Color object intact") if m == :merge
          @data.send(m, h)
          self
        }
      }

      def time
        @data[:timestamp]
      end

      def to_s
        "#{export}"
      end

      def inspect
        "ECell::Elements::Color <#{export}>"
      end

      PROCESSED_EXPORTS = [:exception, :store]
      FILTERED_EXPORTS = [:async, :broadcast]

      def export
        hash = {}
        unpacked!
        PROCESSED_EXPORTS.each { |k|
          next unless @data.key?(k)
          hash[k] = process_export(k, @data[k])
        }
        @data.merge(hash).select { |k,v| !v.nil? && !FILTERED_EXPORTS.include?(k) }
      end

      def process_export(key, data)
        return data if data.is_a?(Hash)
        return unless key && data
        case key
        when :exception
          @data[key] = {
            message: data.message,
            type: data.class.name,
            backtrace: data.backtrace
          }
        when :store
          @data[key] = (data.respond_to? :export) ? data.export : data
        end
      rescue => ex
        caught(ex, "Failed to process export: #{key}.")
      end

      def success?
        !error? && !exception?
      end

      def exception?
        @data[:exception].is_a?(Hash)
      end

      def timeout?
        error?(:timeout)
      end

      def packed?
        @packed === true
      end

      def unpacked!
        unpack! if packed?
        @data
      end

      def [](key)
        #benzrf TODO: why process here but not in the key-named method?
        if PROCESSED_EXPORTS.include?(key)
          process_export(key, @data[key])
        else
          @data[key]
        end
      end

      def []=(key, data)
        if PROCESSED_EXPORTS.include?(key)
          @data[key] = process_export(key, data)
        else
          @data[key] = data
        end
      end

      def symbolized(data=@data)
        return data.reduce({}) do |memo, (k, v)|
          memo.tap { |m| m[static_value(k)] = symbolized(v) }
        end if data.is_a? Hash
        return data.reduce([]) do |memo, v|
          memo << symbolized(v); memo
        end if data.is_a? Array
        data
      rescue => ex
        #benzrf TODO: no `hash` in scope??
        caught(ex, "Failure parsing hash: #{hash.class.name}")
      end

      def packed
        pack!
        @data
      end

      def pack!
        return @data if packed?
        @data = MessagePack.pack(export)
        @packed = true
        self
      end

      def unpack!
        return self unless packed?
        if @data.is_a?(String)
          @data = (@data.strip.chomp.empty?) ? {} : MessagePack.unpack(@data)
        end
        @packed = false
        @data = symbolized
        @data = export
        self
      rescue => ex
        caught(ex, "Trouble unpacking data: #{@data.class.name}", store: @data, local: true)
      end

      def method_missing(method, *args)
        raise "Color entity is corrupted." unless @data.is_a?(Hash)
        if "#{method}".end_with?('?')
          key = "#{method}".sub("?",'').to_sym
          return !@data[key].nil? && (args.empty? || @data[key] == args.first)
        elsif "#{method}".end_with?('=')
          key = "#{method}".sub("=",'').to_sym
          return @data[key] = args.first
        end
        log_warn("Missing #{method} in @data: #{caller[0]}") unless key?(method)
        @data[method]
      end
    end
  end
end

require 'ecell/elements/color_rpc'

#benzrf TODO: figure out where this should go
if false and ECell::Run.identity?(:webstack)
  require 'time'
  ECell::Figures.call_sync(:process).web_trigger(rpc: {message: "RPC #{Time.now.iso8601}"}) { |rpc|
      if rpc.success?
        ECell.sync(:ClientRegistry).clients_announce!("#{rpc.id}[#{rpc.code}] #{rpc.message}.")
        ECell.async(:logging).debug("Ran web_trigger.", store: rpc, quiet: true)
      else
        message = if rpc.message?
          "#{rpc.id}[#{rpc.error}] #{rpc.message}."
        elsif rpc[:exception]
          "#{rpc.id}[#{rpc[:exception][:type]}] #{rpc[:exception][:message]}."
        else
          "There was an unknown error. Sorry about that."
        end
        ECell.sync(:ClientRegistry).clients_announce!(message)
      end
      response = rpc
    }

  ECell::Logger.dump! ECell::Figures.call_async(:process).web_trigger(rpc: {message: "RPC.async #{Time.now.iso8601}"})
end

