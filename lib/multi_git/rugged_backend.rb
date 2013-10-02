require 'rugged'
module MultiGit
  module RuggedBackend
    class << self

      def load!
      end

      # @param (see MultiGit#open)
      # @raise (see MultiGit#open)
      # @option (see MultiGit#open)
      # @return (see MultiGit#open)
      def open(path, options = {})
        Repository.new(path, options)
      end

    end
  end
end
require 'multi_git/rugged_backend/repository'
