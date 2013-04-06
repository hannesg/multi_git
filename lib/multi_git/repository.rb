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
class MultiGit::Repository

protected
  Utils = MultiGit::Utils
  Error = MultiGit::Error

  VALID_TYPES = Set[:blob, :tree, :commit, :tag]
public
  extend Utils::AbstractMethods

  # @!method git_dir
  #   @abstract
  #   Return the repository base directory
  #   @return [String]
  abstract :git_dir

  # @!method bare?
  #   @abstract
  #   Is this repository bare?
  abstract :bare?

  # @!method initialize(directory, options = {})
  #   @param directory [String] a directory
  #   @option options [Boolean] :init init the repository if it doesn't exist
  #   @option options [Boolean] :bare open/init the repository bare

  # @!method read(ref)
  #   Reads a reference.
  #
  #   @abstract
  #
  #   @raise [MultiGit::Error::InvalidReference] if ref is not a valid reference
  #   @raise [MultiGit::Error::AmbiguousReference] if ref refers to multiple objects
  #   @raise [MultiGit::Error::BadRevisionSyntax] if ref does not contain a valid ref-syntax
  #   @param [String] ref
  #   @return [MultiGit::Object] object
  abstract :read

  # @!method include?(oid)
  #   Checks whether this repository contains a given oid.
  #   @abstract
  #   @param [String] oid
  #   @return [Boolean]
  abstract :include?

  # @!method parse(ref)
  #   Resolves a reference into an oid.
  #   @abstract
  #   @param [String] ref
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

  # @!parse alias [] read
  def [](*args,&block)
    read(*args,&block)
  end

  # @visibility private
  def inspect
    if bare?
      ["#<",self.class.name," ",git_dir,">"].join
    else
      ["#<",self.class.name," ",git_dir," checked out at:",git_work_tree,">"].join
    end
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

  def validate_type(type)
    raise Error::InvalidObjectType, type.inspect unless VALID_TYPES.include?(type)
  end

end
