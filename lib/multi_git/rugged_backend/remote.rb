require 'multi_git/remote'
require 'forwardable'
module MultiGit
  module RuggedBackend
    class Remote

      include MultiGit::Remote
      extend Forwardable

      attr :repository

      attr :rugged_remote
      protected :rugged_remote

      def_instance_delegator :rugged_remote, :url, :fetch_url

      # :nocov:
      if Rugged::Remote.instance_methods.include? :push_url
        def_instance_delegator :rugged_remote, :push_url, :push_url
      else
        def push_url
          raise Error::NotYetImplemented, 'Rugged::Remote#push_url is only available in bleeding edge rugged'
        end
      end
      # :nocov:

      def initialize( repository, remote )
        @repository = repository
        @rugged_remote     = remote
      end

      class Persistent < self

        include MultiGit::Remote::Persistent
        extend Forwardable

        def_instance_delegator :rugged_remote, :name

      end

    end
  end
end
