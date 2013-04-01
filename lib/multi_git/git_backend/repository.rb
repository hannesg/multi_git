require 'multi_git/utils'
require 'multi_git/tree_entry'
require 'multi_git/repository'
require 'multi_git/git_backend/cmd'
require 'multi_git/git_backend/blob'
require 'multi_git/git_backend/tree'
module MultiGit::GitBackend

  Executeable = Class.new(Blob){ include MultiGit::Executeable }
  File = Class.new(Blob){ include MultiGit::File }
  Symlink = Class.new(Blob){ include MultiGit::Symlink }
  Directory = Class.new(Tree){ include MultiGit::Directory }

  class Repository

    include MultiGit::Repository

    # @api private
    def __backend__
      @git
    end

    Utils = MultiGit::Utils

    OBJECT_CLASSES = {
      :blob => Blob,
      :tree => Tree
    }

    ENTRY_CLASSES = {
      Utils::MODE_EXECUTEABLE => Executeable,
      Utils::MODE_FILE        => File,
      Utils::MODE_SYMLINK     => Symlink,
      Utils::MODE_DIRECTORY   => Directory
    }

    def bare?
      git_work_tree.nil?
    end

    attr :git_dir
    attr :git_work_tree
    attr :git_binary

    def initialize(path, options = {})
      @git_binary = `which git`.chomp
      options = initialize_options(path, options)
      git_dir = options[:repository]
      @git = Cmd.new(git_binary, :git_dir => git_dir )
      if !::File.exists?(git_dir) || MultiGit::Utils.empty_dir?(git_dir)
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
      if content.kind_of? MultiGit::Object
        if include?(content.oid)
          return read(content.oid)
        end
        content = content.to_io
      end
      if content.respond_to? :path
        oid = @git["hash-object",:t, type.to_s,:w,'--', content.path]
      else
        content = content.read if content.respond_to? :read
        @git.call('hash-object',:t,type.to_s, :w, :stdin) do |stdin, stdout|
          stdin.write(content)
          stdin.close
          oid = stdout.read.chomp
        end
      end
      return OBJECT_CLASSES[type].new(self,oid)
    end

    def read(oidish)
      oid = parse(oidish)
      type = @git['cat-file',:t, oid]
      return OBJECT_CLASSES[type.to_sym].new(self, oid)
    end

    def read_entry(parent = nil, name, mode, oidish)
      oid = parse(oidish)
      type = @git['cat-file',:t, oid]
      verify_type_for_mode(type.to_sym, mode)
      return ENTRY_CLASSES[mode].new(parent, name, self, oid)
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

    def include?(oid)
      begin
        @git['cat-file', :e, oid.to_s]
        return true
      rescue Cmd::Error::ExitCode1
        return false
      end
    end

    MKTREE_FORMAT = "%06o %s %s\t%s\n"

    # @api private
    def make_tree(entries)
      @git.call('mktree') do |stdin, stdout|
        entries.each do |name, mode, oid|
          stdin.printf(MKTREE_FORMAT, mode, Utils.type_from_mode(mode), oid, name)
        end
        stdin.close
        read(stdout.read.chomp)
      end
    end

  end
end
