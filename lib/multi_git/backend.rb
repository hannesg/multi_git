require 'multi_git/utils'
require 'multi_git/error'
module MultiGit

  module Backend

    attr :failed, :exception

    def check(description, &check)
      @checks ||= []
      @checks << [description, check]
    end

    def check!
      @checks.each do |description, check|
        begin 
          result = check.call
          if result == false
            @failed = description
            return
          end
        rescue Exception => e
          @failed = description
          @exception = e
        end
      end
    end

    private :check, :check!

    # @abstract
    #
    # This method implements loading the backend files.
    def load!
      raise NotImplementedError, "Please implement #load! for #{self}"
    end

    # Opens a git repository.
    #
    # @return [Repository]
    def open(directory, options = {})
      load!
      open(directory, options)
    end

    # Tests whether this backend is available.
    def available?
      check!
      @failed.nil?
    end

  end

  module RuggedBackend

    extend Backend

    check "Rugged available" do
      defined?(::Rugged) || 
        Utils.file_loadeable?('rugged.rb')
    end

    def self.load!
      require 'multi_git/rugged_backend'
    end

  end

  module JGitBackend

    extend Backend

    check "Using Jruby" do
      RUBY_ENGINE == "jruby"
    end

    check "Jgit available" do
      defined?(Java::OrgEclipseJgitLib::Repository)
    end

    def self.load!
      require 'multi_git/jgit_backend'
    end

  end

  module GitBackend

    extend Backend

    check "Git Executeable available" do
      `git --version`
    end

    def self.load!
      require 'multi_git/git_backend'
    end

  end
end
