require 'fileutils'
require 'set'
module MultiGit::Repository

  VALID_TYPES = Set[:blob, :tree, :commit, :tag]

  module ClassMethods
    include Forwardable
  end

  def self.included(base)
    base.extend(ClassMethods)
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
    looks_bare = MultiGit::Utils.looks_bare?(path)
    case(options[:bare])
    when nil then
      options[:bare] = looks_bare
    when false then
      raise MultiGit::Error::RepositoryBare, path if looks_bare
    end
    if !File.exists?(path)
      if options[:init]
        FileUtils.mkdir_p(path)
      else
        raise MultiGit::Error::NotARepository, path
      end
    end
    if options[:bare]
      if looks_bare || options[:init]
        options[:repository] ||= path
      else
        options[:repository] ||= File.join(path, '.git')
      end
      options.delete(:working_directory)
    else
      options[:working_directory] = path
      options[:repository] ||= File.join(path, '.git')
    end
    options[:index] ||= File.join(options[:repository],'index')
    return options
  end

  def verify_bareness(path, options)
    bareness = options[:expected_bare]
    return if bareness.nil?
    if !bareness && bare?
      raise MultiGit::Error::RepositoryBare, path
    end
  end

  def validate_type(type)
    raise MultiGit::Error::InvalidObjectType, type.inspect unless VALID_TYPES.include?(type)
  end

end
