require 'multi_git/utils'
require 'multi_git/tree_entry'
require 'multi_git/repository'
require 'multi_git/git_backend/cmd'
require 'multi_git/git_backend/blob'
require 'multi_git/git_backend/tree'
require 'multi_git/git_backend/commit'
require 'multi_git/git_backend/ref'
require 'multi_git/git_backend/config'
require 'multi_git/git_backend/remote'
module MultiGit::GitBackend

  class Repository < MultiGit::Repository

    # @api private
    def __backend__
      @git
    end

    Utils = MultiGit::Utils

    OBJECT_CLASSES = {
      :blob => Blob,
      :tree => Tree,
      :commit => Commit
    }

    def bare?
      git_work_tree.nil?
    end

    attr :git_dir
    attr :git_work_tree
    attr :git_binary

    def initialize(path, options = {})
      @git_binary = `which git`.chomp
      options = initialize_options(path, options)
      git_dir = options[:repository]
      @git = Cmd.new({'GIT_CONFIG_NOSYSTEM'=>'1'}, git_binary, :git_dir => git_dir )
      if !::File.exists?(git_dir) || MultiGit::Utils.empty_dir?(git_dir)
        if options[:init]
          if options[:bare]
            @git['init', :bare, git_dir]
          else
            @git['init', git_dir]
          end
        else
          raise MultiGit::Error::NotARepository, options[:repository]
        end
      end
      @git_dir = git_dir
      @git_work_tree = options[:working_directory]
      @index = options[:index]
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
      oid = nil
      if content.kind_of? MultiGit::Object
        if include?(content.oid)
          return read(content.oid)
        end
        content = content.to_io
      end
      if content.respond_to? :path
        oid = @git["hash-object",:t, type.to_s,:w,'--', content.path].chomp
      else
        content = content.read if content.respond_to? :read
        @git.call('hash-object',:t,type.to_s, :w, :stdin) do |stdin, stdout|
          stdin.write(content)
          stdin.close
          oid = stdout.read.chomp
        end
      end
      return OBJECT_CLASSES[type].new(self,oid)
    end

    # {include:MultiGit::Repository#read}
    # @param (see MultiGit::Repository#read)
    # @raise (see MultiGit::Repository#read)
    # @return (see MultiGit::Repository#read)
    def read(oidish)
      oid = parse(oidish)
      type = @git['cat-file',:t, oid].chomp
      return OBJECT_CLASSES[type.to_sym].new(self, oid)
    end

    # {include:MultiGit::Repository#parse}
    # @param (see MultiGit::Repository#parse)
    # @raise (see MultiGit::Repository#parse)
    # @return (see MultiGit::Repository#parse)
    def parse(oidish)
      begin
        result = @git['rev-parse', :revs_only, :validate, oidish.to_s].chomp
        if result == ""
          raise MultiGit::Error::InvalidReference, oidish
        end
        return result
      rescue Cmd::Error::ExitCode128
        raise MultiGit::Error::InvalidReference, oidish
      end
    end

    # {include:MultiGit::Repository#include?}
    # @param (see MultiGit::Repository#include?)
    # @raise (see MultiGit::Repository#include?)
    # @return (see MultiGit::Repository#include?)
    def include?(oid)
      begin
        @git['cat-file', :e, oid.to_s]
        return true
      rescue Cmd::Error::ExitCode1
        return false
      end
    end

    # {include:MultiGit::Repository#ref}
    # @param (see MultiGit::Repository#ref)
    # @raise (see MultiGit::Repository#ref)
    # @return (see MultiGit::Repository#ref)
    def ref(name)
      validate_ref_name(name)
      MultiGit::GitBackend::Ref.new(self, name)
    end

    def config
      @config ||= Config.new(@git)
    end

    def remote( name_or_url )
      if looks_like_remote_url? name_or_url
        remote = Remote.new(self, name_or_url)
      else
        remote = Remote::Persistent.new(self, name_or_url)
      end
      return remote
    end

  private
    TRUE_LAMBDA = proc{ true }
  public 

    def each_branch(filter = :all)
      return to_enum(:each_branch, filter) unless block_given?
      which = case filter
              when :all, Regexp then [:a]
              when :local       then []
              when :remote      then [:r]
              end
      post_filter = TRUE_LAMBDA
      if filter.kind_of? Regexp
        post_filter = filter
      end
      @git['branch', *which].each_line do |line|
        name = line[2..-2]
        next unless post_filter === name
        yield branch(name)
      end
      return self
    end

    def each_tag
      return to_enum(:each_tag) unless block_given?
      @git['tag'].each_line do |line|
        yield tag(line.chomp)
      end
      return self
    end

    # @visibility private
    MKTREE_FORMAT = "%06o %s %s\t%s\n"

    # @visibility private
    # @api private
    def make_tree(entries)
      @git.call('mktree') do |stdin, stdout|
        entries.each do |name, mode, oid|
          stdin.printf(MKTREE_FORMAT, mode, Utils.type_from_mode(mode), oid, name)
        end
        stdin.close
        read(stdout.read.chomp)
      end
    end

    # @visibility private
    # @api private
    def make_commit(commit)
      env = {
        'GIT_AUTHOR_NAME'=>commit[:author].name,
        'GIT_AUTHOR_EMAIL'=>commit[:author].email,
        'GIT_AUTHOR_DATE' =>commit[:time].strftime('%s %z'),
        'GIT_COMMITTER_NAME'=>commit[:committer].name,
        'GIT_COMMITTER_EMAIL'=>commit[:committer].email,
        'GIT_COMMITTER_DATE' =>commit[:commit_time].strftime('%s %z')
      }
      @git.call_env(env, 'commit-tree', commit[:tree], commit[:parents].map{|p| [:p, p] } ) do |stdin, stdout|
        stdin << commit[:message]
        stdin.close
        return read(stdout.read.chomp)
      end
    end

  end
end
