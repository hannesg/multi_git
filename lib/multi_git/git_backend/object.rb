require 'multi_git/object'
require 'forwardable'
class MultiGit::GitBackend::Object < IO

  extend Forwardable

  include MultiGit::Object

  def initialize(repository, oid, content = nil)
    @repository = repository
    @git = repository.__backend__
    @oid = oid
    @content = content ? content.dup.freeze : nil
  end

  delegate (IO.public_instance_methods-::Object.public_instance_methods) => 'to_io'

  def size
    @size ||= begin
      if @content
        @content.bytesize
      else
        @git['cat-file',:s,@oid].to_i
      end
    end
  end

  def content
    @content ||= @git['cat-file',type.to_s,@oid].freeze
  end

  private :content

  def to_io
    @io ||= StringIO.new(content)
  end

end
