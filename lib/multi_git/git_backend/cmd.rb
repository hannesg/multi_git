require 'shellwords'
require 'open3'
require 'multi_git/error'
module MultiGit::GitBackend

  class Cmd

    class Error < MultiGit::Error::Internal

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

    def initialize(command, options = {})
      @cmd = command
      @opts = options
    end

    READ_BLOCK = lambda{|io|
      io.read.chomp
    }

    def call(*args, &block)
      s = cmd(*args)
      block ||= READ_BLOCK
      result = nil
      message = nil
      status = popen_foo( s.join(' ') ) do | stdin, stdout, stderr |
        if block.arity == 1
          stdin.close
          result = block.call(stdout)
        else
          result = block.call(stdin, stdout)
        end
        message = stderr.read
      end
      if status.exitstatus == 0
        return result
      else
        raise Error[status.exitstatus], message.chomp
      end
    end

    alias [] call

  private

    # @api private
    # 
    # popen3 is broken in jruby, popen4 is not available in mri :(
    def popen_foo(*args)
      if IO.respond_to? :popen4
        IO.popen4(*args) do |_pid, *yield_args|
          yield *yield_args
        end
        return $?
      else
        Open3.popen3(*args) do |*yield_args,_thr|
          yield *yield_args
          return _thr.value
        end
      end
    end

    def cmd(*args)
      [ @cmd, escape_opts(@opts), escape_args(args) ].flatten
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
        opt_to_string(k)+'='+Shellwords.escape(v)
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
