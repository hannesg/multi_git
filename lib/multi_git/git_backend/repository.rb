require 'multi_git/utils'
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
      git_dir = options[:repository]
      @git = Cmd.new( :git_dir => git_dir )
      if !File.exists?(git_dir) || MultiGit::Utils.empty_dir?(git_dir)
        if options[:init]
          if options[:bare]
            @git['init', :bare, git_dir]
          else
            @git['init', git_dir]
          end
        else
          raise MultiGit::Error::NotARepository, options[:repository]
        end
      end
      @git_dir = git_dir
      @git_work_tree = options[:working_directory]
      @index = options[:index]
      verify_bareness(path, options)
    end

    def put(content, type = :blob)
      validate_type(type)
      oid = nil
      if content.respond_to? :path
        oid = @git["hash-object",:t, type.to_s,:w,'--', content.path]
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
      type = @git['cat-file',:t, oid]
      return OBJECT_CLASSES[type.to_sym].new(self, oid)
    end

    def parse(oidish)
      begin
        result = @git['rev-parse', :revs_only, :validate, oidish.to_s]
        if result == ""
          raise MultiGit::Error::InvalidReference, oidish
        end
        return result
      rescue Cmd::Error::ExitCode128
        raise MultiGit::Error::InvalidReference, oidish
      end
    end

  end
end
