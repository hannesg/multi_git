module MultiGit

  module TreeEntry

    def self.for(klass)
      unless klass.const_get(:@Entry)
        klass.const_set(:@Entry, Class.new(klass){ include TreeEntry })
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
