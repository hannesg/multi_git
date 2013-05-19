require 'forwardable'
require 'multi_git/config'
module MultiGit
  module GitBackend
    class Config

      include MultiGit::Config
      extend Forwardable

      delegate :each => :@config

      def initialize(cmd)
        conf = cmd['config','--list']
        @explicit_config = Hash[conf.each_line.map do |line|
          line.chomp.split('=',2)
        end]
        @config = DEFAULTS.merge(@explicit_config)
        @cmd = cmd
      end

    end
  end
end
