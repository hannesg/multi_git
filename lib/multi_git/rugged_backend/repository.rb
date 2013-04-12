require 'multi_git/tree_entry'
require 'multi_git/repository'
require 'multi_git/rugged_backend/blob'
require 'multi_git/rugged_backend/tree'
module MultiGit::RuggedBackend

  class Repository < MultiGit::Repository

    extend Forwardable

  private
    OBJECT_CLASSES = {
      :blob => Blob,
      :tree => Tree
    }

  public

    # {include:MultiGit::Repository#bare?}
    delegate "bare?" => "@git"

    # {include:MultiGit::Repository#git_dir}
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
          @git = Rugged::Repository.init_at(path, !!options[:bare])
        else
          raise MultiGit::Error::NotARepository, path
        end
      end
      verify_bareness(path, options)
    end

    # {include:MultiGit::Repository#write}
    # @param (see MultiGit::Repository#write)
    # @raise (see MultiGit::Repository#write)
    # @return (see MultiGit::Repository#write)
    def write(content, type = :blob)
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

    # {include:MultiGit::Repository#read}
    # @param (see MultiGit::Repository#read)
    # @raise (see MultiGit::Repository#read)
    # @return (see MultiGit::Repository#read)
    def read(ref)
      oid = parse(ref)
      object = @git.lookup(oid)
      return OBJECT_CLASSES[object.type].new(self, oid, object)
    end

    # {include:MultiGit::Repository#parse}
    # @param (see MultiGit::Repository#parse)
    # @raise (see MultiGit::Repository#parse)
    # @return (see MultiGit::Repository#parse)
    def parse(oidish)
      begin
        return Rugged::Object.rev_parse_oid(@git, oidish)
      rescue Rugged::ReferenceError => e
        raise MultiGit::Error::InvalidReference, e
      end
    end

    # {include:MultiGit::Repository#include?}
    # @param (see MultiGit::Repository#include?)
    # @raise (see MultiGit::Repository#include?)
    # @return (see MultiGit::Repository#include?)
    def include?(oid)
      @git.include?(oid)
    end

    # @api private
    # @visibility private
    def __backend__
      @git
    end

    # @api private
    # @visibility private
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
