require 'forwardable'
require 'multi_git/object'
class MultiGit::RuggedBackend::Object < IO

  include MultiGit::Object

  extend Forwardable

  delegate (IO.public_instance_methods-::Object.public_instance_methods) => 'to_io'

  def initialize( repository, oid, object = nil )
    @repository = repository
    @git = repository.__backend__
    @oid = oid
    @rugged_object = object
  end

  def to_io
    @io ||= StringIO.new(content)
  end

  def bytesize
    rugged_odb.len
  end

private
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
