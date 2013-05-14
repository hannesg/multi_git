require 'multi_git/refspec'
module MultiGit

  module Remote

    extend Utils::AbstractMethods

    # @!attribute repository
    #   @return [Repository]
    abstract :repository

    # @!attribute fetch_url
    #   @return [URI]
    abstract :fetch_url

    # @!attribute push_url
    #   @return [URI]
    abstract :push_url

    # @!method fetch( *refspecs )
    #   @param refspecs [RefSpec, String, Range, Hash, ...]
    abstract :fetch

    # @!method push( *refspecs )
    #   @param refspecs [RefSpec, String, Range, Hash, ...]
    abstract :push

    # @!method save( name )
    #   @param name [String]
    #   @return [Persistent]
    abstract :save

    module Persistent
      include Remote
      extend Utils::AbstractMethods

      # @!attrbute name
      #   @return [String, nil]
      abstract :name

      # @!method save( name = name )
      #   @param name [String]
      #   @return [Persistent]
      abstract :save
    end

  end

end
