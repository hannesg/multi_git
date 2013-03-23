require 'multi_git/shared/repository'
module MultiGit::RuggedBackend
  class Repository
    include MultiGit::Repository

    def initialize(path, options = {})
      options = options.dup
      options[:bare] ||= MultiGit::Utils.looks_bare?(path)
      begin
        @git = Rugged::Repository.new(path)
      rescue Rugged::RepositoryError
        if options[:init]
          @git = Rugged::Repository.init_at(path, options[:bare])
        else
          raise MultiGit::Error::NotARepository, path
        end
      end
    end

  end
end
