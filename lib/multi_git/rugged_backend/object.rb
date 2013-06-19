require 'forwardable'
require 'multi_git/object'
class MultiGit::RuggedBackend::Object

  include MultiGit::Object

  extend Forwardable
  extend MultiGit::Utils::Memoizes

  def initialize( repository, oid, object = nil )
    @repository = repository
    @git = repository.__backend__
    @oid = oid
    set_memoized_rugged_object(object) if object
  end

  def to_io
    StringIO.new(content)
  end

  def bytesize
    rugged_odb.len
  end

  def content
    rugged_odb.data.freeze
  end

  memoize :content

protected

  def rugged_object
    @git.lookup(@oid)
  end

  memoize :rugged_object

  def rugged_odb
    @git.read(@oid)
  end

  memoize :rugged_odb

end
