require 'shellwords'
module MultiGit::GitBackend

  class Cmd

    def initialize(options = {})
      @cmd = 'env -i git'
      @opts = options
    end

    def simple(*args)
      s = cmd_string(*args)
      c = `#{s}`.chomp
      return $?, c
    end

    def run(*args)
    end

    def io(*args, &block)
      options = args.last.kind_of?(Hash) ? args.pop.dup : {}
      args << options
      s = cmd_string(*args)
      IO.popen(s, 'r+', &block)
      return $?
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
