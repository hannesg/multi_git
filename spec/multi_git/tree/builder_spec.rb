require 'multi_git/tree/builder'
describe MultiGit::Tree::Builder, :tree_builder => true do

  def subject
    MultiGit::Tree::Builder
  end

  it "is awesome" do
    bld = subject.new
  end

  it "can add files" do
    bld = subject.new
    bld.file "foo"
    expect(bld['foo']).to be_a(MultiGit::File::Builder)
    expect(bld['foo'].parent).to eql bld
  end

  it "can add directories" do
    bld = subject.new
    bld.directory "foo"
    expect(bld['foo']).to be_a(MultiGit::Directory::Builder)
    expect(bld['foo'].parent).to eql bld
  end

  it "can add nested directories" do
    bld = subject.new
    bld.directory "foo" do
      directory "bar"
    end
    expect(bld['foo']['bar']).to be_a(MultiGit::Directory::Builder)
  end

  it "can add nested directories with []=" do
    bld = subject.new
    bld['foo/bar'] = "blob"
    expect(bld['foo']['bar']).to be_a(MultiGit::File::Builder)
  end

  it "doesn't create directories if create: false is supplied" do
    bld = subject.new
    expect{
      bld['foo/bar', create: false] = "blob"
    }.to raise_error(MultiGit::Error::InvalidTraversal, /doesn't contain/)
  end

  it "doesn't overwrite directories" do
    bld = subject.new
    bld.file 'foo'
    expect{
      bld['foo/bar'] = "blob"
    }.to raise_error(MultiGit::Error::InvalidTraversal, /does contain/)
  end

  it "does overwrite directories if specified" do
    bld = subject.new
    bld.file 'foo'
    bld['foo/bar', create: :overwrite] = "blob"
    expect(bld['foo']['bar']).to be_a(MultiGit::File::Builder)
  end

  it "can add links" do
    bld = subject.new
    bld['foo'] = 'blob'
    bld.link('bar', 'foo')
    expect(bld['bar', follow:false].resolve).to eql bld['foo']
  end

  it "is nesteable" do
    bld1 = subject.new
    bld1.file 'foo'
    bld2 = subject.new(bld1)
    expect(bld2['foo']).to be_a(MultiGit::File::Builder)
  end

  it "is covers overwritten entries" do
    bld1 = subject.new
    bld1.file 'foo'
    bld2 = subject.new(bld1)
    bld2.directory('foo')
    expect(bld2['foo']).to be_a(MultiGit::Directory::Builder)
    expect(bld2.names).to eql ['foo']
  end

  describe '#changed?' do

    context 'with an emtpy from-tree' do
      subject do
        MultiGit::Tree::Builder.new do
          file 'a', 'x'
          directory 'b' do
            file 'c', 'y'
          end
        end
      end

      it 'reports a new file as changed' do
        expect(subject.changed?('a')).to be_true
      end

      it 'reports a new dir as changed' do
        expect(subject.changed?('b')).to be_true
      end

      it 'reports a new file in a dir as changed' do
        expect(subject.changed?('b/c')).to be_true
      end

      it 'doesn\'t report a non-existing file as changed' do
        expect(subject.changed?('d')).to be_false
      end

      it 'reports the whole builder as changed' do
        expect(subject.changed?).to be_true
      end
    end

    context 'with a non-emtpy from-tree' do
      subject do
        from = MultiGit::Tree::Builder.new do
          file 'a', 'x'
          directory 'b' do
            file 'c', 'y'
          end
        end
        MultiGit::Tree::Builder.new(from) do
          file 'p','z'
          delete 'a'
        end
      end

      it 'reports a new file as changed' do
        expect(subject.changed?('p')).to be_true
      end

      it 'reports a deleted file as changed' do
        expect(subject.changed?('a')).to be_true
      end

      it 'doesn\'t report am unchanged file as changed' do
        expect(subject.changed?('b/c')).to be_false
      end

      it 'doesn\'t report am unchanged dir as changed' do
        expect(subject.changed?('b')).to be_false
      end

      it 'doesn\'t report a non-existing file as changed' do
        expect(subject.changed?('d')).to be_false
      end

      it 'reports the whole builder as changed' do
        expect(subject.changed?).to be_true
      end
    end

    context 'when nothing has changed' do
      subject do
        from = MultiGit::Tree::Builder.new do
          file 'a', 'x'
          directory 'b' do
            file 'c', 'y'
            file 'd', 'z'
          end
        end
        MultiGit::Tree::Builder.new(from) do
          file 'a'  , 'x'
          file 'b/c', 'y'
        end
      end

      it 'doesn\'t report am unchanged file as changed' do
        expect(subject.changed?('b/c')).to be_false
      end

      it 'doesn\'t report am unchanged dir as changed' do
        expect(subject.changed?('b')).to be_false
      end

      it 'doesn\'t report a non-existing file as changed' do
        expect(subject.changed?('d')).to be_false
      end

      it 'doesn\'t reports the whole builder as changed' do
        expect(subject.changed?).to be_false
      end
    end



  end

end
