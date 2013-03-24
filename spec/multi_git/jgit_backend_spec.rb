describe MultiGit::JGitBackend, :jgit => true, :if => MultiGit::JGitBackend.available? do

  it_behaves_like "a MultiGit backend"

end
