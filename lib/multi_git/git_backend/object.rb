require 'multi_git/object'
require 'forwardable'
class MultiGit::GitBackend::Object

  extend Forwardable
  extend MultiGit::Utils::Memoizes

  include MultiGit::Object

  def initialize(repository, oid, content = nil)
    @repository = repository
    @git = repository.__backend__
    @oid = oid
    if content
      set_memoized_content( content.dup.freeze )
    end
  end

  def bytesize
    if @content
      @content.bytesize
    else
      @git['cat-file',:s,@oid].to_i
    end
  end

  memoize :bytesize

  def content
    @git['cat-file',type.to_s,@oid].freeze
  end

  memoize :content

  def to_io
    StringIO.new(content)
  end

end
