require 'multi_git/repository'
require 'multi_git/git_backend/cmd'
require 'multi_git/git_backend/blob'
require 'multi_git/git_backend/tree'
module MultiGit::GitBackend
  class Repository

    include MultiGit::Repository

    # @api private
    def __backend__
      @git
    end

    OBJECT_CLASSES = {
      :blob => Blob,
      :tree => Tree
    }

    def bare?
      git_work_tree.nil?
    end

    attr :git_dir
    attr :git_work_tree

    def initialize(path, options = {})
      options = initialize_options(path, options)
      @git = Cmd.new( :git_dir => options[:repository] )
      if !File.exists?(options[:repository])
        if options[:init]
          if options[:bare]
            @git.simple('init', :bare, options[:repository])
          else
            @git.simple('init', options[:repository])
          end
        else
          raise MultiGit::Error::NotARepository, options[:repository]
        end
      end
      @git_dir = options[:repository]
      @git_work_tree = options[:working_directory]
      @index = options[:index]
      verify_bareness(path, options)
    end

    def put(content, type = :blob)
      validate_type(type)
      oid = nil
      if content.respond_to? :path
        _,oid = @git.simple("hash-object",:t, type.to_s,:w,'--', content.path)
      else
        content = content.read if content.respond_to? :read
        @git.io('hash-object',:t,type.to_s, :w, :stdin) do |io|
          io.write(content)
          io.close_write
          oid = io.read.strip
        end
      end
      return OBJECT_CLASSES[type].new(self,oid)
    end

    def read(oidish)
      oid = parse(oidish)
      _, type = @git.simple('cat-file',:t, oid)
      return OBJECT_CLASSES[type.to_sym].new(self, oid)
    end

    def parse(oidish)
      status,result = @git.simple('rev-parse', :revs_only, :validate, oidish.to_s)
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
