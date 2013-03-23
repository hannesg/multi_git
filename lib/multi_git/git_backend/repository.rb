require 'multi_git/shared/repository'
module MultiGit::GitBackend
  class Repository

    include MultiGit::Repository

    def initialize(path, options = {})
      options = options.dup
      if options[:bare] ||= MultiGit::Utils.looks_bare?(path)
        options[:repository] ||= path
      else
        options[:working_directory] = path
        options[:repository] ||= File.join(path, '.git')
      end
      options[:index] ||= File.join(options[:repository],'index')
      if !File.exists?(options[:repository])
        if options[:init]
          if options[:bare]
            Git::Lib.new(options).send(:command, 'init', ['--bare', options[:repository]])
          else
            Git::Lib.new(options).init
          end
        else
          raise MultiGit::Error::NotARepository, options[:repository]
        end
      end
      @git = Git.open(path, options)
    end

  end
end
