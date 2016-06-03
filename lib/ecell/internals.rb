module ECell::Internals
  class Blocker
    include ECell::Extensions

    def method_missing(method, data={}, &block)
      error!(:shutdown)
    end
  end
end

