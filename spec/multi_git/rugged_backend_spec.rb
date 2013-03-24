describe MultiGit::RuggedBackend, :rugged => true, :if => MultiGit::RuggedBackend.available? do

  it_behaves_like "a MultiGit backend"

end
