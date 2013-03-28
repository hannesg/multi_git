module MultiGit

  module TreeEntry

    def self.for(klass)
      if klass.const_defined?(:Entry)
        klass.const_get(:Entry)
      else
        klass.const_set(:Entry, Class.new(klass){ include TreeEntry })
      end
    end

    attr :name
    attr :mode

    def initialize(name, mode,*args, &block)
      @name = name
      @mode = mode
      super(*args, &block)
    end

  end

end
