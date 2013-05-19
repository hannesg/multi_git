require 'forwardable'
require 'multi_git/config'
module MultiGit
  module RuggedBackend
    class Config

      include MultiGit::Config
      extend Forwardable

      delegate :each => :@config

      def initialize(rugged_config)
        @rugged_config = rugged_config
        @config = DEFAULTS.merge(@rugged_config.to_hash)
      end

    private

      attr :rugged_config

    end
  end
end
