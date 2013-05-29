require 'forwardable'
require 'multi_git/config'
module MultiGit
  module GitBackend
    class Config

      include MultiGit::Config

      def initialize(cmd)
        @cmd = cmd
      end

      def get( section, subsection, key )
        s = schema_for(section, subsection, key)
        begin
          if s.list?
            value = @cmd['config', '--get-all', qualified_key(section, subsection, key)].lines.map(&:chomp)
          else
            value = @cmd['config', '--get', qualified_key(section, subsection, key)].chomp
          end
          return s.convert(value)
        rescue Cmd::Error::ExitCode1
          return s.default
        end
      end

      def each_explicit_key
        return to_enum(:each_explicit_key) unless block_given?
        @cmd.('config','--list') do |io|
          io.each_line do |line|
            name, _ = line.split('=',2)
            yield *split_key(name)
          end
        end
        return self
      end


    end
  end
end
