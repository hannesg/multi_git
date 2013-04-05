module MultiGit

  module Backend

    def check(description, &check)
      @checks ||= []
      @checks << [description, check]
    end

    def check!
      @checks.each do |description, check|
        begin 
          result = check.call
          if result == false
            @failed = [description, nil]
            return
          end
        rescue Exception => e
          @failed = [description, e]
        end
      end
    end

    def file_loadeable?(file)
      $LOAD_PATH.any?{|path| File.exists?( File.join(path, file) ) }
    end

    def load!
      raise "Please implement load! for #{self}"
    end

    def open(*args, &block)
      load!
      open(*args, &block)
    end

    def available?
      check!
      @failed.nil?
    end

    def fail
      @failed
    end

  end

  module RuggedBackend

    extend Backend

    check "Rugged available" do
      defined?(::Rugged) || 
        file_loadeable?('rugged.rb')
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
