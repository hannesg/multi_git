require 'multi_git/config/schema'
describe MultiGit::Config::Schema do

  context "example #1" do

    let(:schema) do
      MultiGit::Config::Schema.build do
        section 'core' do
          int 'repositoryformatversion', 0
          bool 'filemode', true
          bool 'bare', false
        end
        section 'color' do
          bool 'branch', false
          section 'branch' do
            string 'current'
          end
        end
        section 'remote' do
          any_section do
            array 'url'
            string 'fetch'
          end
        end
      end
    end

    it 'has the correct value for an int' do
      expect( schema['core'][nil]['repositoryformatversion'] ).to be_a MultiGit::Config::Schema::Integer
    end

    it 'has the correct value for a bool' do
      expect( schema['core'][nil]['bare'] ).to be_a MultiGit::Config::Schema::Boolean
    end

    it 'can have a value and a section with the same name' do
      expect( schema['color'][nil]['branch'] ).to be_a MultiGit::Config::Schema::Boolean
      expect( schema['color']['branch']['current'] ).to be_a MultiGit::Config::Schema::String
    end

    it 'can edit the default section' do
      expect( schema['remote']['i_dont_exist']['url'] ).to be_a MultiGit::Config::Schema::Array
    end

  end

end
