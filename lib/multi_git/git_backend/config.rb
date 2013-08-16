require 'forwardable'
require 'set'
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
          # git < 1.8.0 barfs when using --get on a multiply defined 
          #  value, but uses the last value internally.
          # git >= 1.8.0 simply returns the last value
          value = @cmd['config', '--get-all', qualified_key(section, subsection, key)].lines.map(&:chomp)
          value = value.last unless s.list?
          return s.convert(value)
        rescue Cmd::Error::ExitCode1
          return s.default
        rescue Cmd::Error::ExitCode2
          raise Error::DuplicateConfigKey, qualified_key(section, subsection, key)
        end
      end

      def set( section, subsection, key, value )
        s = schema_for(section, subsection, key)
        qk = qualified_key(section, subsection, key)
        if value.kind_of? Array
          @cmd['config', '--unset-all', qk]
          value.each do | r |
            @cmd['config', qk, :add, value.to_s]
          end
        else
          @cmd['config', qk, value.to_s]
        end
      end

      def each_explicit_key
        return to_enum(:each_explicit_key) unless block_given?
        seen = Set.new
        @cmd.('config','--list') do |io|
          io.each_line do |line|
            name, _ = line.split('=',2)
            next if seen.include? name
            seen << name
            yield *split_key(name)
          end
        end
        return self
      end


    end
  end
end
