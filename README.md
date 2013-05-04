multi\_git - use all the git!
============================

[![Build Status](https://travis-ci.org/hannesg/multi_git.png?branch=master)](https://travis-ci.org/hannesg/multi_git)
[![Coverage Status](https://coveralls.io/repos/hannesg/multi_git/badge.png?branch=master)](https://coveralls.io/r/hannesg/multi_git)

multi\_git provides access to git repositories in ruby.

Usage
--------------------

### Opening a repository

    repository = MultiGit.open('/my/repo')

### Initializing a repository

    repository = MultiGit.open('/my/repo', init: true)

### Getting a directory ("tree" in git terms)

    master = repository['master']

### Getting a file in a directory ("blob" in git terms)

    master / 'filename' # => MultiGit::File

### Getting a file in a subdirectory

    master / 'dirname' / 'filename' # => MultiGit::File

### Writing something to a branch

    master.commit do
      tree['filename'] = 'content'
    end

Install
---------------------------

It's a gem ;)

All backends require some more software installed. For rugged and jgit, see
the examples directory. For the git backend, just install git via apt/yum/brew/
... what you've probably already done when you are using rvm or bundler.

Backends
---------------------------

multi\_git comes with three different backends:

  - Git Backend
    
    Pros:
      - pure-ruby
      - requires just the git binary
    
    Cons:
      - spawns processes a lot (slow)
  - JGit Backend ( see [example](examples/jgit/) )
    
    Pros:
      - build upon jgit jar which is quite fast and stable
      - no shell-out
    
    Cons:
      - requires jruby
  - Rugged Backend ( see [example](examples/rugged/) )
    
    Pros:
      - build upon libgit2, the new git library
      - no shell-out
    
    Cons:
      - require mri or rubinius

TODO ( loosely by priority )
-----------------------------

- Correctnes: handle symbolic refs gracefuly
- Feature: Config
- Feature: Ref#update(:reckless)
- Efficiency: efficient Ref#resolve+update
- Feature: Remotes/Clone/Push/Fetch ( blocked by config )
- Code Quality: Unify memoizing
- Awesomeness: benchmark backends against each other
- Feature: Index/Working Directory
- Feature: RefWalks
- Feature: Gitlab integration
- Feature: Github integration
- Feature: Fat Tags
- Feature: Submodules ( blocked by config )
- Feature: RefLog
- Awesomeness: World dominance

Authors
-----------------

- Hannes Georg @hannesg42

License
------------------

Copyright (C) 2013 Hannes Georg

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
