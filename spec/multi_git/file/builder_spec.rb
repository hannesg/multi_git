require 'multi_git/file'
describe MultiGit::File::Builder, :file_builder => true do

  let(:name){
    'a_name'
  }

  it "is initializeable with string content" do
    b = MultiGit::File::Builder.new(nil, name, "Blobs")
  end

end
