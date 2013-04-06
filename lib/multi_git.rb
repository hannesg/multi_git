require 'forwardable'
require 'multi_git/backend'
require 'multi_git/backend_set'
require 'multi_git/error'
require 'multi_git/utils'
module MultiGit

  BACKENDS = BackendSet.new
  BACKENDS[   :git, priority: 0] = GitBackend
  BACKENDS[:rugged, priority: 1] = RuggedBackend
  BACKENDS[  :jgit, priority: 2] = JGitBackend

  extend SingleForwardable

  # Determines the best available backend..
  #
  # @return [Backend]
  delegate :best => 'MultiGit::BACKENDS'

  # @!method open( directory, options = {} )
  #
  #   Opens a git repository.
  #
  #   @return [Repository]
  #
  #   @see Backend
  # 
  delegate :open => 'best'

end
