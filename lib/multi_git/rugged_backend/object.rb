require 'forwardable'
require 'multi_git/object'
class MultiGit::RuggedBackend::Object

  include MultiGit::Object

  extend Forwardable

  def initialize( repository, oid, object = nil )
    @repository = repository
    @git = repository.__backend__
    @oid = oid
    @rugged_object = object
  end

  def to_io
    StringIO.new(content)
  end

  def bytesize
    rugged_odb.len
  end

  def content
    @content ||= rugged_odb.data.freeze
  end

protected

  def rugged_object
    @rugged_object ||= @git.lookup(@oid)
  end

  def rugged_odb
    @rugged_odb ||= @git.read(@oid)
  end

end
