require 'multi_git/shared/repository'
require 'multi_git/rugged_backend/blob'
module MultiGit::RuggedBackend
  class Repository
    include MultiGit::Repository

    OBJECT_CLASSES = {
      :blob => Blob
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
      validate_type(type)
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
      return OBJECT_CLASSES[type].new(@git, oid)
    end

    def read(oidish)
      oid = parse_oid(oidish)
      odb = @git.read(oid)
      return OBJECT_CLASSES[odb.type].new(@git, oid, odb: odb)
    end

    def parse_oid(oidish)
      return oidish
    end

  private

    def strip_slash(path)
      return nil if path.nil?
      return path[0..-2]
    end

  end
end
