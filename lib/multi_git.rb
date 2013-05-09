require 'forwardable'
require 'multi_git/version'
require 'multi_git/backend'
require 'multi_git/backend_set'
require 'multi_git/error'
require 'multi_git/utils'
module MultiGit

private

  BACKENDS = BackendSet.new
  BACKENDS[   :git, priority: 0] = GitBackend
  BACKENDS[:rugged, priority: 1] = RuggedBackend
  BACKENDS[  :jgit, priority: 2] = JGitBackend

  SLASH = '/'.freeze

public

  extend SingleForwardable

  # @!method best
  #   Determines the best available backend..
  #   @return [Backend]
  delegate :best => 'MultiGit::BACKENDS'

  # @!method open( directory, options = {} )
  #
  #   Opens a git repository.
  #
  #   @example
  #     # setup:
  #     dir = `mktemp -d`
  #     # example:
  #     MultiGit.open(dir, init: true) #=> be_a MultiGit::Repository
  #     # teardown:
  #     `rm -rf #{dir}`
  #
  #
  #   @return [Repository]
  #
  #   @see Backend
  # 
  delegate :open => 'best'

end
