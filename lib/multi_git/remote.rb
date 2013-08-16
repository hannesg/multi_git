require 'multi_git/refspec'
module MultiGit

  module Remote

    extend Utils::AbstractMethods

    # @!attribute repository
    #   @return [Repository]
    abstract :repository

    # @!attribute fetch_urls
    #   @return [Enumerable<URI>]
    abstract :fetch_urls

    # @!attribute push_urls
    #   @return [Enumerable<URI>]
    abstract :push_urls

    # @!method fetch( *refspecs )
    #   @param refspecs [RefSpec, String, Range, Hash, ...]
    #   @return self
    abstract :fetch

    # @!method push( *refspecs )
    #   @param refspecs [RefSpec, String, Range, Hash, ...]
    #   @return self
    abstract :push

    # @!method save( name )
    #   @param name [String]
    #   @return [Persistent]
    abstract :save

    module Persistent
      include Remote
      extend Utils::AbstractMethods

      # @!attribute name
      #   @return [String, nil]
      abstract :name

      # @!method save( name = name )
      #   @param name [String]
      #   @return [Persistent]
      abstract :save

    protected

      def fetch_refspec_parser
        RefSpec::Parser.new("refs/remotes/#{name}/")
      end

    end

  protected

    def parse_fetch_refspec(*refspecs)
      fetch_refspec_parser[*refspecs]
    end

    def parse_push_refspec(*refspecs)
      push_refspec_parser[*refspecs]
    end

    def fetch_refspec_parser
      RefSpec::Parser.new("refs/remotes//")
    end

    def push_refspec_parser
      RefSpec::Parser.new('refs/heads/')
    end


  end

end
