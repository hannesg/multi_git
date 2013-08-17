List of Inconsistencies
=======================

This list contains all inconsistencies this project can or should not handle in ruby.

- Situation: a config key is supplied multiple times but you ask only for one of them
  - git: uses the _last_ value
  - libgit2: uses the _last_ value
  - jgit: uses the _first_ value (code)[http://code.ohloh.net/file?fid=mfTUTzRVeBYtXiPyCjqf4zFzmgU&cid=p8tsHiPpsik&s=&browser=Default#L608]

- Situation: the config is manipulated by a different process while the repo is opened with multi_git
  - git: picks up the new setting immediately
  - libgit2/jgit: picks up the new setting after a reload or similiar
