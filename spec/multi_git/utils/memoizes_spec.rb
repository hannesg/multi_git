require 'multi_git/utils'

describe MultiGit::Utils::Memoizes do

  context "with simple memoization" do

    subject do
      Class.new do
        attr :called

        def simple_method
          @called += 1
        end

        def nil_method
          @called += 1
          nil
        end

        def initialize
          @called = 0
        end

        extend MultiGit::Utils::Memoizes

        memoize :simple_method, :nil_method
      end
    end

    it "memoizes simple method calls" do
      c = subject.new
      expect( c.simple_method ).to eql 1
      expect( c.simple_method ).to eql 1
      expect( c.called ).to eql 1
    end

    it "memoizes nil method calls" do
      c = subject.new
      expect( c.nil_method ).to eql nil
      expect( c.nil_method ).to eql nil
      expect( c.called ).to eql 1
    end

  end

  context "with synchronized memoization" do

    subject do
      Class.new do
        attr :synchronize_called, :called

        def simple_method
          @called += 1
        end

        def nil_method
          @called += 1
          nil
        end

        def initialize
          @called = 0
          @synchronize_called = 0
        end

        def synchronize
          @synchronize_called += 1
          yield
        end

        extend MultiGit::Utils::Memoizes

        memoize :simple_method, :nil_method, synchronize: true
      end
    end

    it "memoizes simple method calls" do
      c = subject.new
      expect( c.simple_method ).to eql 1
      expect( c.simple_method ).to eql 1
      expect( c.called ).to eql 1
      expect( c.synchronize_called ).to eql 1
    end

    it "memoizes nil method calls" do
      c = subject.new
      expect( c.nil_method ).to eql nil
      expect( c.nil_method ).to eql nil
      expect( c.called ).to eql 1
      expect( c.synchronize_called ).to eql 1
    end

  end
end
