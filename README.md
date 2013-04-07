multi\_git - use all the git!
============================

[![Build Status](https://travis-ci.org/hannesg/multi_git.png?branch=master)](https://travis-ci.org/hannesg/multi_git)
[![Coverage Status](https://coveralls.io/repos/hannesg/multi_git/badge.png?branch=master)](https://coveralls.io/r/hannesg/multi_git)

multi\_git provides access to git repositories in ruby.

Usage
--------------------

    repo = MultiGit.open('my_repo', init: true)

Backends
---------------------------

multi\_git comes with three different backends:

  - Git Backend
    
    Pros:
      - pure-ruby
      - requires just the git binary
    
    Cons:
      - forks a lot (slow)
  - JGit Backend ( see [example](examples/jgit/) )
    
    Pros:
      - build upon jgit jar which is quite fast and stable
      - no forking
    
    Cons:
      - requires jruby
  - Rugged Backend ( see [example](examples/rugged/ )
    
    Pros:
      - build upon libgit2, the new git library
      - no forking
    
    Cons:
      - require mri or rubinius
