require 'multi_git/tree_entry'
require 'multi_git/repository'
require 'multi_git/rugged_backend/blob'
require 'multi_git/rugged_backend/tree'
module MultiGit::RuggedBackend

  Executeable = Class.new(Blob){ include MultiGit::Executeable }
  File = Class.new(Blob){ include MultiGit::File }
  Symlink = Class.new(Blob){ include MultiGit::Symlink }
  Directory = Class.new(Tree){ include MultiGit::Directory }

  class Repository
    include MultiGit::Repository

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

    delegate "bare?" => "@git"

    def git_dir
      strip_slash @git.path
    end

    def git_work_tree
      strip_slash @git.workdir
    end

    def initialize(path, options = {})
      options = initialize_options(path,options)
      begin
        @git = Rugged::Repository.new(options[:repository])
        if options[:working_directory]
          @git.workdir = options[:working_directory]
        end
      rescue Rugged::RepositoryError, Rugged::OSError
        if options[:init]
          @git = Rugged::Repository.init_at(path, options[:bare])
        else
          raise MultiGit::Error::NotARepository, path
        end
      end
      verify_bareness(path, options)
    end

    #
    def put(content, type = :blob)
      if content.kind_of? MultiGit::Builder
        return content >> self
      end
      validate_type(type)
      if content.kind_of? MultiGit::Object
        if include?(content.oid)
          return read(content.oid)
        end
        content = content.to_io
      end
      #if content.respond_to? :path
        # file duck-type
      #  oid = @git.hash_file(content.path, type)
      #  return OBJECT_CLASSES[type].new(@git, oid)
      #els
      if content.respond_to? :read
        # IO duck-type
        content = content.read
      end
      oid = @git.write(content.to_s, type)
      return OBJECT_CLASSES[type].new(self, oid)
    end

    def read(oidish)
      oid = parse(oidish)
      object = @git.lookup(oid)
      return OBJECT_CLASSES[object.type].new(self, oid, object)
    end

    # @api private
    def read_entry(parent = nil, name, mode, oidish)
      oid = parse(oidish)
      object = @git.lookup(oid)
      verify_type_for_mode(object.type, mode)
      return ENTRY_CLASSES[mode].new(parent, name, self, oid, object)
    end

    def parse(oidish)
      begin
        return Rugged::Object.rev_parse_oid(@git, oidish)
      rescue Rugged::ReferenceError => e
        raise MultiGit::Error::InvalidReference, e
      end
    end

    def include?(oid)
      @git.include?(oid)
    end

    # @api private
    def __backend__
      @git
    end

    # @api private
    def make_tree(entries)
      builder = Rugged::Tree::Builder.new
      entries.each do |name, mode, oid|
        builder << { name: name, oid: oid, filemode: mode}
      end
      oid = builder.write(@git)
      return read(oid)
    end

  private

    def strip_slash(path)
      return nil if path.nil?
      return path[0..-2]
    end

  end
end
