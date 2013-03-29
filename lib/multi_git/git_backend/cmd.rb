require 'shellwords'
require 'multi_git/error'
module MultiGit::GitBackend

  class Cmd

    class Error
      
      def self.const_missing(name)
        if name =~ /\AExitCode\d+\z/
          self.const_set(name, Class.new(self))
        else
          super
        end
      end

      def self.[](exit_code)
        return const_get("ExitCode#{exit_code}")
      end

    end

    def initialize(options = {})
      @cmd = 'env -i git'
      @opts = options
    end

    def [](*args)
      s = cmd_string(*args)
      c = `#{s}`.chomp
      unless $?.exitstatus == 0
        raise Error[$?.exitstatus], s
      end
      return c
    end

    def run(*args)
    end

    def io(*args, &block)
      options = args.last.kind_of?(Hash) ? args.pop.dup : {}
      args << options
      s = cmd_string(*args)
      result = IO.popen(s, 'r+', &block)
      unless $?.exitstatus == 0
        raise Error[$?.exitstatus], s
      end
      return result
    end

  private

    def cmd_string(*args)
      [ @cmd, escape_opts(@opts), escape_args(args) , '2>&1'].flatten.join(' ')
    end

    def escape_args(args)
      args.map{|arg|
        if arg.kind_of? Hash
          escape_opts(arg)
        elsif arg.kind_of? Array
          escape_args(arg)
        else
          Shellwords.escape(opt_to_string(arg))
        end
      }
    end

    def escape_opts(opts)
      opts.map{|k,v|
        Shellwords.escape(opt_to_string(k)+'='+v)
      }
    end

    def opt_to_string(opt)
      if opt.kind_of? Symbol
        s = opt.to_s
        if s.size == 1
          return '-'+s
        else
          return '--'+s.gsub('_','-')
        end
      else
        return opt
      end
    end

  end

end
