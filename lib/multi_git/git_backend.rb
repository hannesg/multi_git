module MultiGit
  module GitBackend
    class << self

      def load!
      end

      def available?
        true
      end

      def open(directory, options = {})
        Repository.new(directory, options)
      end

    end
  end
end
require 'multi_git/git_backend/repository'
