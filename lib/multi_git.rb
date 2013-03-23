require 'multi_git/backend'
require 'multi_git/error'
require 'multi_git/utils'
module MultiGit

  class << self

    def best
      @best ||= Backend.best
    end

    def current
      @current ||= best
    end

    def current=(backend)
      if backend == :best
        @current = best
      else
        @current = Backend[backend]
      end
    end

    def open(path, options = {} )
      bo = options[:backend] || :current
      backend = case bo
        when :current then current
        when :best    then best
        else Backend[bo]
      end
      backend.open(path, options)
    end

  end

end
