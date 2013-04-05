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

  delegate :best => 'MultiGit::BACKENDS'

  delegate :open => 'best'

end
