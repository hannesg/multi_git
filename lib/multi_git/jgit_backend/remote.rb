require 'multi_git/remote'
module MultiGit
  module JGitBackend
    class Remote

      include MultiGit::Remote

      attr :repository

      class Persistent < self

        include MultiGit::Remote::Persistent

        def initialize( repository, name )
          @repository = repository
          @java_config = Java::OrgEclipseJgitTransport::RemoteConfig.new(repository.config.to_java, name)
        end

        def name
          java_config.getName
        end

      end

      REMOTE_SECTION = 'remote'.to_java
      TEMPORARY_SECTION = 'tmp'.to_java
      FETCH_URL_KEY = 'url'.to_java
      PUSH_URL_KEY = 'pushurl'.to_java

      FETCH = Java::OrgEclipseJgitTransport::Transport::Operation::FETCH
      PUSH  = Java::OrgEclipseJgitTransport::Transport::Operation::PUSH

      def initialize( repository, url, push_url = url )
        @repository = repository
        conf = Java::OrgEclipseJgitLib::Config.new
        conf.setStringList(REMOTE_SECTION, TEMPORARY_SECTION, FETCH_URL_KEY, Array(url))
        conf.setStringList(REMOTE_SECTION, TEMPORARY_SECTION, PUSH_URL_KEY, Array(push_url))
        @java_config = Java::OrgEclipseJgitTransport::RemoteConfig.new(conf, TEMPORARY_SECTION)
      end

      def fetch_urls
        java_config.getURIs.map(&:to_s)
      end

      def push_urls
        pu = java_config.getPushURIs.map(&:to_s)
        pu.any? ? pu : fetch_urls
      end

      def fetch( *refspecs )
        rs = parse_fetch_refspec(*refspecs).map{|refspec| Java::OrgEclipseJgitTransport::RefSpec.new(refspec.to_s) }
        use_transport( FETCH ) do | transport |
          transport.fetch( transport_monitor, rs )
        end
        self
      end

      def push( *refspecs )
        rs = parse_push_refspec(*refspecs).map{|refspec| Java::OrgEclipseJgitTransport::RefSpec.new(refspec.to_s) }
        use_transport( PUSH ) do | transport |
          toPush = transport.findRemoteRefUpdatesFor( rs )
          transport.push( transport_monitor, toPush )
        end
        self
      end

    private

      attr :java_config

      def use_transport( op )
        tr = Java::OrgEclipseJgitTransport::Transport.open(repository.__backend__, java_config, op)
        yield tr
      ensure
        tr.close
      end

      def transport_monitor
        Java::OrgEclipseJgitLib::NullProgressMonitor::INSTANCE
      end

    end
  end
end
