require 'multi_git/repository'
require 'multi_git/git_backend/cmd'
require 'multi_git/git_backend/blob'
module MultiGit::GitBackend
  class Repository

    include MultiGit::Repository

    # @api private
    def __backend__
      @git
    end

    OBJECT_CLASSES = {
      :blob => Blob
    }

    def bare?
      @git.dir.nil? || !File.exists?(@git.dir.to_s)
    end

    def git_dir
      @git.repo.path
    end

    def git_work_tree
      bare? ? nil : @git.dir.to_s
    end

    def initialize(path, options = {})
      options = initialize_options(path, options)
      if !File.exists?(options[:repository])
        if options[:init]
          if options[:bare]
            Git::Lib.new(options).send(:command, 'init', ['--bare', options[:repository]])
          else
            Git::Lib.new(options).init
          end
        else
          raise MultiGit::Error::NotARepository, options[:repository]
        end
      end
      @git = Git::Base.new(options)
      @cmd = Cmd.new( :git_dir => options[:repository] )
      verify_bareness(path, options)
    end

    def put(content, type = :blob)
      validate_type(type)
      oid = nil
      if content.respond_to? :path
        oid = @git.lib.send(:command, "hash-object", ['-t',type.to_s,'-w','--', content.path])
      else
        content = content.read if content.respond_to? :read
        @cmd.io('hash-object',:t,type.to_s, :w, :stdin) do |io|
          io.write(content)
          io.close_write
          oid = io.read.strip
        end
      end
      return OBJECT_CLASSES[type].new(self,oid)
    end

    def read(oidish)
      oid = parse(oidish)
      type = @git.lib.object_type(oid).to_sym
      return OBJECT_CLASSES[type].new(self, oid)
    end

    def parse(oidish)
      status,result = @cmd.simple('rev-parse', :revs_only, :validate, oidish.to_s)
      if result == ""
        raise MultiGit::Error::InvalidReference, oidish
      end
      case(status.exitstatus)
      when 0 then return result
      when 128
        raise MultiGit::Error::InvalidReference, oidish
      else
        raise ArgumentError
      end
    end

  end
end
