require 'multi_git/backend'
module MultiGit

  class BackendSet

    def initialize
      @backends = {}
      @priorities = {}
    end

    def []=(name, options={}, value)
      raise ArgumentError, "Expected a MultiGit::Backend, got #{value.inspect}" unless value.respond_to? :available?
      @priorities[name] = options.fetch(:priority, 0)
      @backends[name] = value
    end

    def [](name)
      if name.kind_of? Backend
        return name
      elsif name == :best
        return best
      else
        return @backends[name]
      end
    end

    def priority(name)
      @priorities[name]
    end

    def best
      @priorities.sort_by{|_,value| -value}.find do |name, _|
        be = self[name]
        return be if be.available?
      end
    end

  end

end
