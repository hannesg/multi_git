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
module MultiGit::Repository

  Utils = MultiGit::Utils
  Error = MultiGit::Error

  VALID_TYPES = Set[:blob, :tree, :commit, :tag]

  module ClassMethods
    include Forwardable
  end

  def self.included(base)
    base.extend(ClassMethods)
  end

  def [](*args,&block)
    read(*args,&block)
  end

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
