# 0.0.1

* [ENHANCEMENT] Tree::Builder#changed? now assumes the main directory
* [BUG] Comparing Trees/Tree::Builders now actually works

# 0.0.1.rc1

* [FEATURE] Pushing to a remote now works
* [ENHANCEMENT] Got object/builder equality right
* [FEATURE] Added Tree::Builder#changed? method to test for changes
* [CHANGE] Rugged backend is not supported on ruby < 1.9.3 anymore because rugged itself ceased support

# 0.0.1.beta1

* [FEATURE] basic remotes support
* [FEATURE] Repository#config
* [ENHANCEMENT] Ref#update is now more flexible (reckless updating, updating without block)
* [ENHANCEMENT] Tree#glob now supports DOTMATCH
* [ENHANCEMENT] Repository#head method to get the current HEAD
* [BUG] Removed Tree#path ( did not made much sense since the path is not known )
* [BUG] Detaching symbolic references now works as expected

# 0.0.1.alpha2

* [FEATURE] Tree#glob ( works like directory globbing )
* [FEATURE] Tree#walk ( works like #each, just recursive )
* [FEATURE] branch listing with repository#each_branch
* [FEATURE] tag listing with repository#each_tag

# 0.0.1.alpha1

* Initial Release
