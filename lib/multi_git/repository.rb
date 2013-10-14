require 'fileutils'
require 'set'
require 'multi_git/utils'
require 'multi_git/error'
require 'multi_git/tree_entry'
require 'multi_git/symlink'
require 'multi_git/directory'
require 'multi_git/file'
require 'multi_git/executeable'
require 'multi_git/submodule'

# Abstract base class for all repository implementations.
#
# @example Creating a new repository
#   # setup:
#   dir = `mktemp -d`
#   # example:
#   repo = MultiGit.open(dir, init: true) #=> be_a MultiGit::Repository
#   repo.bare? #=> eql false
#   repo.git_dir #=> eql dir + '/.git'
#   repo.git_work_tree #=> eql dir
#   # creating a first commit:
#   repo.branch('master').commit do
#     tree['file'] = 'content'
#   end
#   # teardown:
#   `rm -rf #{dir}`
#
# @abstract
class MultiGit::Repository

protected
  Utils = MultiGit::Utils
  Error = MultiGit::Error

  VALID_TYPES = Set[:blob, :tree, :commit, :tag]
public
  extend Utils::AbstractMethods

  # @!method config
  #   @abstract
  #   Returns the config
  #   @return [Config]
  abstract :config

  # @!method git_dir
  #   @abstract
  #   Returns the repository directory (the place where the internal stuff is stored)
  #   @return [String]
  abstract :git_dir

  # @!method git_work_tree
  #   @abstract
  #   Returns the working directory (the place where your files are)
  #   @return [String]
  abstract :git_work_tree

  # @!method bare?
  #   @abstract
  #   Is this repository bare?
  abstract :bare?

  # @!group Object interface

  # @!method read(expression)
  #   Reads an object from the database.
  #
  #   @see http://git-scm.com/docs/git-rev-parse#_specifying_revisions Revision expression syntax
  #   @abstract
  #
  #   @raise [MultiGit::Error::InvalidReference] if ref is not a valid reference
  #   @raise [MultiGit::Error::AmbiguousReference] if ref refers to multiple objects
  #   @raise [MultiGit::Error::BadRevisionSyntax] if ref does not contain a valid ref-syntax
  #   @param [String] expression
  #   @return [MultiGit::Object] object
  abstract :read

  # @!method include?(oid)
  #   Checks whether this repository contains a given oid.
  #   @abstract
  #   @param [String] oid
  #   @return [Boolean]
  abstract :include?

  # @!method parse(expression)
  #   Resolves an expression into an oid.
  #   @abstract
  #
  #   @see http://git-scm.com/docs/git-rev-parse#_specifying_revisions Revision expression syntax
  #   @param [String] expression
  #   @raise [MultiGit::Error::InvalidReference] if ref is not a valid reference
  #   @raise [MultiGit::Error::AmbiguousReference] if ref refers to multiple objects
  #   @raise [MultiGit::Error::BadRevisionSyntax] if ref does not contain a valid ref-syntax
  #   @return [String] oid
  abstract :parse

  # @!method write(content)
  #   Writes something to the repository.
  #
  #   If called with a String or an IO, this method creates a {MultiGit::Blob} with the
  #   given content. This is the easiest way to create blobs.
  #
  #   If called with a {MultiGit::Object}, this method determines if the object does already exist
  #   and writes it otherwise.
  #
  #   If called with a {MultiGit::Builder}, this method inserts the content of the builder to the
  #   repository. This is the easiest way to create trees/commits.
  #
  #   @abstract
  #   @param [String, IO, MultiGit::Object, MultiGit::Builder] content
  #   @return [MultiGit::Object] the resulting object
  abstract :write

  # @!parse alias_method :<<, :write
  def <<(*args,&block)
    write(*args,&block)
  end

  # @!endgroup
  # @!group References interface

  # @!method ref(name)
  #   Opens a reference. A reference is usually known as branch or tag.
  #
  #   @example
  #     # setup:
  #     dir = `mktemp -d`
  #     # example:
  #     repo = MultiGit.open(dir, init: true) #=> be_a MultiGit::Repository
  #     master_branch = repo.ref('refs/heads/master')
  #     head = repo.ref('HEAD')
  #     # teardown:
  #     `rm -rf #{dir}`
  #
  #   @abstract
  #   @param [String] name
  #   @return [MultiGit::Ref] ref
  abstract :ref

  # Gets the HEAD ref.
  # @return [Ref] head
  def head
    return ref('HEAD')
  end

  # Opens a branch
  #
  # @example
  #   # setup:
  #   dir = `mktemp -d`
  #   # example:
  #   repository = MultiGit.open(dir, init: true)
  #   # getting a local branch
  #   repository.branch('master') #=> be_a MultiGit::Ref
  #   # getting a remote branch
  #   repository.branch('origin/master') #=> be_a MultiGit::Ref
  #   # teardown:
  #   `rm -rf #{dir}`
  #
  # @param name [String] branch name
  # @return [Ref]
  def branch(name)
    if name.include? '/'
      ref('refs/remotes/'+name)
    else
      ref('refs/heads/'+name)
    end
  end

  # Opens a tag
  #
  # @param name [String] tag name
  # @return [Ref]
  def tag(name)
    ref('refs/tags/'+name)
  end

  # @method each_branch( filter = :all )
  #   Yields either all, local or remote branches. If called
  #   with a regular expression it will be used to filter the
  #   branches by name.
  #
  #   @param filter [:all, :local, :remote, Regexp]
  #   @yield branch
  #   @yieldparam branch [Ref]
  #   @return [Enumerable<Ref>] if called without block
  #
  abstract :each_branch

  # @method each_tag
  #   Yields all tags.
  #
  #   @yield tag
  #   @yieldparam tag [Ref]
  #   @return [Enumerable<Ref>] if called without block
  #
  abstract :each_tag

  # @!parse alias_method :[], :ref
  def [](name)
    ref(name)
  end

  # !@endgroup

  # @visibility private
  def inspect
    if bare?
      ["#<",self.class.name," ",git_dir,">"].join
    else
      ["#<",self.class.name," ",git_dir," checked out at:",git_work_tree,">"].join
    end
  end

  # @visibility private
  EC = {
    Utils::MODE_EXECUTEABLE => MultiGit::Executeable,
    Utils::MODE_FILE        => MultiGit::File,
    Utils::MODE_SYMLINK     => MultiGit::Symlink,
    Utils::MODE_DIRECTORY   => MultiGit::Directory
  }

  # @visibility private
  def read_entry(parent = nil, name, mode, oidish)
    obj = read(oidish)
    EC[mode].new(parent, name, obj)
  end
protected

  def initialize_options(path, options)
    options = options.dup
    options[:expected_bare] = options[:bare]
    looks_bare = Utils.looks_bare?(path)
    case(options[:bare])
    when nil then
      options[:bare] = looks_bare
    when false then
      raise Error::RepositoryBare, path if looks_bare
    end
    if !::File.exists?(path)
      if options[:init]
        FileUtils.mkdir_p(path)
      else
        raise Error::NotARepository, path
      end
    end
    if options[:bare]
      if looks_bare || options[:init]
        options[:repository] ||= path
      else
        options[:repository] ||= ::File.join(path, '.git')
      end
      options.delete(:working_directory)
    else
      options[:working_directory] = path
      options[:repository] ||= ::File.join(path, '.git')
    end
    options[:index] ||= ::File.join(options[:repository],'index')
    return options
  end

  def verify_bareness(path, options)
    bareness = options[:expected_bare]
    return if bareness.nil?
    if !bareness && bare?
      raise Error::RepositoryBare, path
    end
  end

  def verify_type_for_mode(type, mode)
    expected = Utils.type_from_mode(mode)
    unless type == expected
      raise Error::WrongTypeForMode.new(expected, type)
    end
  end

  VALID_REF = %r{\Arefs/heads/\w+|refs/tags/\w+|refs/remotes/\w+/\w+|[A-Z0-9_]+}

  def validate_ref_name(name)
    unless VALID_REF =~ name
      raise Error::InvalidReferenceName, name
    end
  end

  def validate_type(type)
    raise Error::InvalidObjectType, type.inspect unless VALID_TYPES.include?(type)
  end

  def looks_like_remote_url?(string)
    # poor but efficient
    string.include? '/'
  end

end

