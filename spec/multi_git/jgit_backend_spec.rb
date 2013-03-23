describe MultiGit::JGitBackend, :if => MultiGit::JGitBackend.available? do

  it_behaves_like "a MultiGit backend"

end
