module MultiGit
  module GitBackend
    class << self

      def load!
      end

      def available?
        true
      end

      # @param (see MultiGit#open)
      # @raise (see MultiGit#open)
      # @option (see MultiGit#open)
      # @return (see MultiGit#open)
      def open(directory, options = {})
        Repository.new(directory, options)
      end

    end
  end
end
require 'multi_git/git_backend/repository'
