require 'multi_git/repository'
require 'multi_git/tree_entry'
require 'multi_git/jgit_backend/blob'
require 'multi_git/jgit_backend/tree'
module MultiGit::JGitBackend

  Executeable = Class.new(Blob){ include MultiGit::Executeable }
  File = Class.new(Blob){ include MultiGit::File }
  Symlink = Class.new(Blob){ include MultiGit::Symlink }
  Directory = Class.new(Tree){ include MultiGit::Directory }

  class Repository
    include MultiGit::Repository

    delegate "bare?" => "@git"

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
          oid = inserter.insert(t_id.to_java(:int), ::File.size(content.path).to_java(:long), reader)
        else
          content = content.read if content.respond_to? :read
          oid = inserter.insert(t_id, content.bytes.to_a.to_java(:byte))
        end
        return OBJECT_CLASSES[type].new(self, oid)
      ensure
        reader.close if reader
        inserter.release if inserter
      end
    end

    def read(oidish)
      java_oid = parse_java(oidish)
      object = use_reader{|rdr| rdr.open(java_oid) }
      type = REVERSE_OBJECT_TYPE_IDS.fetch(object.getType)
      return OBJECT_CLASSES[type].new(self, java_oid, object)
    end

    # @api private
    def read_entry(name, mode, oidish)
      java_oid = parse_java(oidish)
      object = use_reader{|rdr| rdr.open(java_oid) }
      #type = REVERSE_OBJECT_TYPE_IDS.fetch(object.getType)
      return ENTRY_CLASSES[mode].new(name, mode, self, java_oid, object)
    end

    def parse(oidish)
      return Java::OrgEclipseJgitLib::ObjectId.toString(parse_java(oidish))
    end

    # @api private
    def parse_java(oidish)
      begin
        oid = @git.resolve(oidish)
        if oid.nil?
          raise MultiGit::Error::InvalidReference, oidish
        end
        return oid
      rescue Java::OrgEclipseJgitErrors::AmbiguousObjectException => e
        raise MultiGit::Error::AmbiguousReference, e
      rescue Java::OrgEclipseJgitErrors::RevisionSyntaxException => e
        raise MultiGit::Error::BadRevisionSyntax, e
      end
    end

    # @api private
    def use_reader
      begin
        rdr = @git.getObjectDatabase.newReader
        result = yield rdr
      ensure
        rdr.release if rdr
      end
    end 

    # @api private
    def __backend__
      @git
    end
  end
end
