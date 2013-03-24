require 'multi_git/shared/repository'
require 'multi_git/jgit_backend/blob'
module MultiGit::JGitBackend
  class Repository
    include MultiGit::Repository

    delegate "bare?" => "@git"

    OBJECT_CLASSES = {
      :blob => Blob
    }

    # These IDs are magic numbers
    # from the Jgit code:
    OBJECT_TYPE_IDS = {
      :commit => 1,
      :tree => 2,
      :blob => 3,
      :tag => 4
    }

    REVERSE_OBJECT_TYPE_IDS = Hash[ OBJECT_TYPE_IDS.map{|k,v| [v,k]} ]

    def git_dir
      @git.getDirectory.to_s
    end

    def git_work_tree
      bare? ? nil : @git.getWorkTree.to_s
    end

    def initialize(path, options = {})
      options = initialize_options(path,options)
      builder = Java::OrgEclipseJgitStorageFile::FileRepositoryBuilder.new
      builder.setGitDir(Java::JavaIO::File.new(options[:repository]))
      if options[:working_directory]
        builder.setWorkTree(Java::JavaIO::File.new(options[:working_directory]))
      end
      if options[:index]
        builder.setIndexFile(Java::JavaIO::File.new(options[:index]))
      end
      @git = builder.build
      if !@git.getObjectDatabase().exists
        if options[:init]
          @git.create(!!options[:bare])
        else
          raise MultiGit::Error::NotARepository, path
        end
      end
      verify_bareness(path, options)
    end

    def put(content, type = :blob)
      validate_type(type)
      t_id = OBJECT_TYPE_IDS[type]
      inserter = nil
      reader = nil
      begin
        inserter = @git.getObjectDatabase.newInserter
        if content.respond_to? :path
          path = content.path
          reader = Java::JavaIO::FileInputStream.new(path)
          oid = inserter.insert(t_id.to_java(:int), File.size(content.path).to_java(:long), reader)
        else
          content = content.read if content.respond_to? :read
          oid = inserter.insert(t_id, content.bytes.to_a.to_java(:byte))
        end
        return OBJECT_CLASSES[type].new(@git, oid)
      ensure
        reader.close if reader
        inserter.release if inserter
      end
    end

    def read(oidish)
      java_oid = parse_java(oidish)
      rdr = @git.getObjectDatabase.newReader
      object = rdr.open(java_oid)
      type = REVERSE_OBJECT_TYPE_IDS.fetch(object.getType)
      return OBJECT_CLASSES[type].new(@git, java_oid, object)
    end

    def parse(oidish)
      return Java::OrgEclipseJgitLib::ObjectId.toString(parse_java(oidish))
    end

    def parse_java(oidish)
      return @git.resolve(oidish)
    end

  end
end
