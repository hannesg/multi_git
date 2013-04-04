multi\_git - use all the git!
============================

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
  - JGit Backend ( see [examples/jgit/README.md](example) )
    Pros:
      - build upon jgit jar which is quite fast and stable
      - no forking
    Cons:
      - requires jruby
  - Rugged Backend ( see [examples/rugged/README.md](example) )
    Pros:
      - build upon libgit2, the new git library
      - no forking
    Cons:
      - require mri or rubinius
