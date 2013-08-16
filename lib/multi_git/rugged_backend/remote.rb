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

      def fetch_urls
        [rugged_remote.url]
      end

      # :nocov:
      if Rugged::Remote.instance_methods.include? :push_url
        def push_urls
          [rugged_remote.push_url || rugged_remote.url]
        end
      else
        def push_urls
          raise Error::NotYetImplemented, 'Rugged::Remote#push_urls is only available in bleeding edge rugged'
        end
      end
      # :nocov:

      def initialize( repository, remote )
        @repository = repository
        @rugged_remote = remote
      end

      class Persistent < self

        include MultiGit::Remote::Persistent
        extend Forwardable

        def_instance_delegator :rugged_remote, :name

      end

    def save( name )
      rugged_remote.rename!( name )
    end

    if Rugged::Remote.instance_methods.include? :clear_refspecs
      def fetch(*refspecs)
        rs = parse_fetch_refspec(*refspecs)
        cl = Rugged::Remote.new(repository.__backend__, fetch_urls.first)
        cl.clear_refspecs
        rs.each do |spec|
          cl.add_fetch(spec.to_s)
        end
        cl.connect(:fetch) do |r|
          r.download
        end
        cl.update_tips!
      end
    else
      def fetch(*_)
        raise Error::NotYetImplemented, 'This rugged version doesn\'t seem to support fetching. You may want to install from HEAD.'
      end
    end

    def push(*refspecs)
      rs = parse_push_refspec(*refspecs).map(&:to_s)
      # rugged cannot push to multiple locations currently
      push_urls.each do | pu |
        cl = Rugged::Remote.new(repository.__backend__, pu)
        cl.clear_refspecs
        cl.push(rs)
      end
    end

    end
  end
end
