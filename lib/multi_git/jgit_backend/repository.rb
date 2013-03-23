require 'multi_git/shared/repository'
module MultiGit::JGitBackend
  class Repository
    include MultiGit::Repository

    def initialize(path, options = {})
      builder = Java::OrgEclipseJgitStorageFile::FileRepositoryBuilder.new
      if options[:bare] ||= MultiGit::Utils.looks_bare?(path)
        builder.setGitDir(Java::JavaIO::File.new(path))
      else
        builder.setWorkTree(Java::JavaIO::File.new(path))
      end
      if options[:bare]
        builder.setBare
      end
      @git = builder.build
      if !@git.getObjectDatabase().exists
        if options[:init]
          @git.create(options[:bare])
        else
          raise MultiGit::Error::NotARepository, path
        end
      end
    end
  end
end
