require File.dirname(__FILE__) + '/spec_helper'

describe Stapler::Uploader do
  
  before do
    @uploader_class = Class.new(Stapler::Uploader)
    @uploader = @uploader_class.new
  end
  
  after do
    FileUtils.rm_rf(public_path)
  end
  
  describe '.version' do
    it "should add it to .versions" do
      @uploader_class.version :thumb
      @uploader_class.versions[:thumb].should be_a(Class)
      @uploader_class.versions[:thumb].ancestors.should include(@uploader_class)
    end
    
    it "should add an accessor which returns the version" do
      @uploader_class.version :thumb
      @uploader.thumb.should be_a(@uploader_class)
    end
    
    it "should add it to #versions which returns the version" do
      @uploader_class.version :thumb
      @uploader.versions[:thumb].should be_a(@uploader_class)
    end
    
    it "should set the version name" do
      @uploader_class.version :thumb
      @uploader.version_name.should == nil
      @uploader.thumb.version_name.should == :thumb
    end
    
    it "should set the version name on the class" do
      @uploader_class.version :thumb
      @uploader.class.version_name.should == nil
      @uploader.thumb.class.version_name.should == :thumb
    end
    
    it "should remember mount options" do
      model = mock('a model')
      @uploader_class.version :thumb
      @uploader = @uploader_class.new(model, :gazelle)

      @uploader.thumb.model.should == model
      @uploader.thumb.mounted_as.should == :gazelle
    end
    
    it "should apply any overrides given in a block" do
      @uploader_class.version :thumb do
        def store_dir
          public_path('monkey/apache')
        end
      end
      @uploader.store_dir.should == 'public/uploads'
      @uploader.thumb.store_dir.should == public_path('monkey/apache')
    end
    
  end
  
  describe '.process' do
    it "should add a single processor when a symbol is given" do
      @uploader_class.process :sepiatone
      @uploader.should_receive(:sepiatone)
      @uploader.process!
    end
    
    it "should add multiple processors when an array of symbols is given" do
      @uploader_class.process :sepiatone, :desaturate, :invert
      @uploader.should_receive(:sepiatone)
      @uploader.should_receive(:desaturate)
      @uploader.should_receive(:invert)
      @uploader.process!
    end
    
    it "should add a single processor with an argument when a hash is given" do
      @uploader_class.process :format => 'png'
      @uploader.should_receive(:format).with('png')
      @uploader.process!
    end

    it "should add a single processor with several argument when a hash is given" do
      @uploader_class.process :resize => [200, 300]
      @uploader.should_receive(:resize).with(200, 300)
      @uploader.process!
    end
    
    it "should add multiple processors when an hash with multiple keys is given" do
      @uploader_class.process :resize => [200, 300], :format => 'png'
      @uploader.should_receive(:resize).with(200, 300)
      @uploader.should_receive(:format).with('png')
      @uploader.process!
    end
  end
  
  describe ".storage" do
    before do
      Stapler::Storage::File.stub!(:setup!)
      Stapler::Storage::S3.stub!(:setup!)
    end
    
    it "should set the storage if an argument is given" do
      storage = mock('some kind of storage')
      storage.should_receive(:setup!)
      @uploader_class.storage storage
      @uploader_class.storage.should == storage
    end
    
    it "should default to file" do
      @uploader_class.storage.should == Stapler::Storage::File
    end
    
    it "should set the storage from the configured shortcuts if a symbol is given" do
      @uploader_class.storage :file
      @uploader_class.storage.should == Stapler::Storage::File
    end
    
    it "should remember the storage when inherited" do
      @uploader_class.storage :s3
      subclass = Class.new(@uploader_class)
      subclass.storage.should == Stapler::Storage::S3
    end
    
    it "should be changeable when inherited" do
      @uploader_class.storage :s3
      subclass = Class.new(@uploader_class)
      subclass.storage.should == Stapler::Storage::S3
      subclass.storage :file
      subclass.storage.should == Stapler::Storage::File
    end
  end
  
  describe '#store_dir' do
    it "should default to the config option" do
      @uploader.store_dir.should == 'public/uploads'
    end
  end
  
  describe '#cache_dir' do
    it "should default to the config option" do
      @uploader.cache_dir.should == 'public/uploads/tmp'
    end
  end
  
  describe '#root' do
    it "should default to the config option" do
      @uploader.root.should == public_path('..')
    end
  end
  
  describe '#filename' do
    it "should default to nil" do
      @uploader.filename.should be_nil
    end
  end
  
  describe '#model' do
    it "should be remembered from initialization" do
      model = mock('a model object')
      @uploader = @uploader_class.new(model)
      @uploader.model.should == model
    end
  end
  
  describe '#mounted_as' do
    it "should be remembered from initialization" do
      model = mock('a model object')
      @uploader = @uploader_class.new(model, :llama)
      @uploader.model.should == model
      @uploader.mounted_as.should == :llama
    end
  end
  
  describe '#url' do
    before do
      Stapler::Uploader.stub!(:generate_cache_id).and_return('20071201-1234-345-2255')
    end
    
    it "should default to nil" do
      @uploader.url.should be_nil
    end
    
    it "should get the directory relative to public, prepending a slash" do
      @uploader.cache!(File.open(file_path('test.jpg')))
      @uploader.url.should == '/uploads/tmp/20071201-1234-345-2255/test.jpg'
    end
    
    it "should return file#url if available" do
      @uploader.cache!(File.open(file_path('test.jpg')))
      @uploader.file.stub!(:url).and_return('http://www.example.com/someurl.jpg')
      @uploader.url.should == 'http://www.example.com/someurl.jpg'
    end
    
    it "should get the directory relative to public, if file#url is blank" do
      @uploader.cache!(File.open(file_path('test.jpg')))
      @uploader.file.stub!(:url).and_return('')
      @uploader.url.should == '/uploads/tmp/20071201-1234-345-2255/test.jpg'
    end
  end
  
  describe '#to_s' do
      before do
        Stapler::Uploader.stub!(:generate_cache_id).and_return('20071201-1234-345-2255')
      end

      it "should default to nil" do
        @uploader.to_s.should be_nil
      end

      it "should get the directory relative to public, prepending a slash" do
        @uploader.cache!(File.open(file_path('test.jpg')))
        @uploader.to_s.should == '/uploads/tmp/20071201-1234-345-2255/test.jpg'
      end

      it "should return file#url if available" do
        @uploader.cache!(File.open(file_path('test.jpg')))
        @uploader.file.stub!(:url).and_return('http://www.example.com/someurl.jpg')
        @uploader.to_s.should == 'http://www.example.com/someurl.jpg'
      end
    end
  
  describe '#cache!' do
    
    before do
      Stapler::Uploader.stub!(:generate_cache_id).and_return('20071201-1234-345-2255')
    end
    
    it "should cache a file" do
      @uploader.cache!(File.open(file_path('test.jpg')))
      @uploader.file.should be_an_instance_of(Stapler::SanitizedFile)
    end
    
    it "should store the cache name" do
      @uploader.cache!(File.open(file_path('test.jpg')))
      @uploader.cache_name.should == '20071201-1234-345-2255/test.jpg'
    end
    
    it "should set the filename to the file's sanitized filename" do
      @uploader.cache!(File.open(file_path('test.jpg')))
      @uploader.filename.should == 'test.jpg'
    end
    
    it "should move it to the tmp dir" do
      @uploader.cache!(File.open(file_path('test.jpg')))
      @uploader.file.path.should == public_path('uploads/tmp/20071201-1234-345-2255/test.jpg')
      @uploader.file.exists?.should be_true
    end
    
    it "should set the url" do
      @uploader.cache!(File.open(file_path('test.jpg')))
      @uploader.url.should == '/uploads/tmp/20071201-1234-345-2255/test.jpg'
    end
    
    it "should trigger a process!" do
      @uploader.should_receive(:process!)
      @uploader.cache!(File.open(file_path('test.jpg')))
    end
  end
  
  describe '#retrieve_from_cache!' do
    it "should cache a file" do
      @uploader.retrieve_from_cache!('20071201-1234-345-2255/test.jpeg')
      @uploader.file.should be_an_instance_of(Stapler::SanitizedFile)
    end
    
    it "should set the path to the tmp dir" do
      @uploader.retrieve_from_cache!('20071201-1234-345-2255/test.jpeg')
      @uploader.current_path.should == public_path('uploads/tmp/20071201-1234-345-2255/test.jpeg')
    end
    
    it "should overwrite a file that has already been cached" do
      @uploader.retrieve_from_cache!('20071201-1234-345-2255/test.jpeg')
      @uploader.retrieve_from_cache!('20071201-1234-345-2255/bork.txt')
      @uploader.current_path.should == public_path('uploads/tmp/20071201-1234-345-2255/bork.txt')
    end
    
    it "should store the cache_name" do
      @uploader.retrieve_from_cache!('20071201-1234-345-2255/test.jpeg')
      @uploader.cache_name.should == '20071201-1234-345-2255/test.jpeg'
    end
    
    it "should store the filename" do
      @uploader.retrieve_from_cache!('20071201-1234-345-2255/test.jpeg')
      @uploader.filename.should == 'test.jpeg'
    end
    
    it "should set the url" do
      @uploader.retrieve_from_cache!('20071201-1234-345-2255/test.jpeg')
      @uploader.url.should == '/uploads/tmp/20071201-1234-345-2255/test.jpeg'
    end
    
    it "should raise an error when the cache_id has an invalid format" do
      running {
        @uploader.retrieve_from_cache!('12345/test.jpeg')
      }.should raise_error(Stapler::InvalidParameter)
      
      @uploader.file.should be_nil
      @uploader.filename.should be_nil
      @uploader.cache_name.should be_nil
    end
    
    it "should raise an error when the original_filename contains invalid characters" do
      running {
        @uploader.retrieve_from_cache!('20071201-1234-345-2255/te/st.jpeg')
      }.should raise_error(Stapler::InvalidParameter)
      running {
        @uploader.retrieve_from_cache!('20071201-1234-345-2255/te??%st.jpeg')
      }.should raise_error(Stapler::InvalidParameter)
      
      @uploader.file.should be_nil
      @uploader.filename.should be_nil
      @uploader.cache_name.should be_nil
    end
  end
  
  describe '#retrieve_from_cache' do
    it "should cache a file" do
      @uploader.retrieve_from_cache('20071201-1234-345-2255/test.jpeg')
      @uploader.file.should be_an_instance_of(Stapler::SanitizedFile)
    end
    
    it "should not overwrite a file that has already been cached" do
      @uploader.retrieve_from_cache('20071201-1234-345-2255/test.jpeg')
      @uploader.retrieve_from_cache('20071201-1234-345-2255/bork.txt')
      @uploader.current_path.should == public_path('uploads/tmp/20071201-1234-345-2255/test.jpeg')
    end

    it "should do nothing when the cache_id has an invalid format" do
      @uploader.retrieve_from_cache('12345/test.jpeg')
      @uploader.file.should be_nil
      @uploader.filename.should be_nil
      @uploader.cache_name.should be_nil
    end
    
    it "should do nothing when the filename contains invalid characters" do
      @uploader.retrieve_from_cache('20071201-1234-345-2255/te??%st.jpeg')
      @uploader.file.should be_nil
      @uploader.filename.should be_nil
      @uploader.cache_name.should be_nil
    end
  end
  
  describe '#store!' do
    before do
      @file = File.open(file_path('test.jpg'))

      @stored_file = mock('a stored file')
      @stored_file.stub!(:path).and_return('/path/to/somewhere')
      @stored_file.stub!(:url).and_return('http://www.example.com')
      @stored_file.stub!(:identifier).and_return('this-is-me')
      
      @uploader_class.storage.stub!(:store!).and_return(@stored_file)
    end
  
    it "should set the current path" do
      @uploader.store!(@file)
      @uploader.current_path.should == '/path/to/somewhere'
    end
    
    it "should set the url" do
      @uploader.store!(@file)
      @uploader.url.should == 'http://www.example.com'
    end
    
    it "should set the identifier" do
      @uploader.store!(@file)
      @uploader.identifier.should == 'this-is-me'
    end
    
    it "should, if a file is given as argument, cache that file" do
      @uploader.should_receive(:cache!).with(@file)
      @uploader.store!(@file)
    end
    
    it "should, if a files is given as an argument and use_cache is false, not cache that file" do
      Stapler.config[:use_cache] = false
      @uploader.should_not_receive(:cache!)
      @uploader.store!(@file)
      Stapler.config[:use_cache] = true
    end
    
    it "should use a previously cached file if no argument is given" do
      @uploader.should_not_receive(:cache!)
      @uploader.store!
    end
    
    it "should instruct the storage engine to store the file" do
      @uploader.cache!(@file)
      @uploader_class.storage.should_receive(:store!).with(@uploader, @uploader.file).and_return(:monkey)
      @uploader.store!
    end
    
    it "should reset the cache_name" do
      @uploader.cache!(@file)
      @uploader.store!
      @uploader.cache_name.should be_nil
    end

    it "should cache the result given by the storage engine" do
      @uploader.store!(@file)
      @uploader.file.should == @stored_file
    end
  end
  
  describe '#retrieve_from_store!' do
    before do
      @stored_file = mock('a stored file')
      @stored_file.stub!(:path).and_return('/path/to/somewhere')
      @stored_file.stub!(:url).and_return('http://www.example.com')
      @stored_file.stub!(:identifier).and_return('this-is-me')

      @uploader_class.storage.stub!(:retrieve!).and_return(@stored_file)
    end

    it "should set the current path" do
      @uploader.retrieve_from_store!('monkey.txt')
      @uploader.current_path.should == '/path/to/somewhere'
    end

    it "should set the url" do
      @uploader.retrieve_from_store!('monkey.txt')
      @uploader.url.should == 'http://www.example.com'
    end

    it "should set the identifier" do
      @uploader.retrieve_from_store!('monkey.txt')
      @uploader.identifier.should == 'this-is-me'
    end
    
    it "should instruct the storage engine to retrieve the file and store the result" do
      @uploader_class.storage.should_receive(:retrieve!).with(@uploader, 'monkey.txt').and_return(@stored_file)
      @uploader.retrieve_from_store!('monkey.txt')
      @uploader.file.should == @stored_file
    end
    
    it "should overwrite a file that has already been cached" do
      @uploader.retrieve_from_cache!('20071201-1234-345-2255/test.jpeg')
      @uploader.retrieve_from_store!('bork.txt')
      @uploader.file.should == @stored_file
    end
  end
  
  describe '#retrieve_from_store' do
    before do
      @stored_file = mock('a stored file')
      @stored_file.stub!(:path).and_return('/path/to/somewhere')
      @stored_file.stub!(:url).and_return('http://www.example.com')
      @stored_file.stub!(:identifier).and_return('this-is-me')

      @uploader_class.storage.stub!(:retrieve!).and_return(@stored_file)
    end

    it "should set the current path" do
      @uploader.retrieve_from_store('monkey.txt')
      @uploader.current_path.should == '/path/to/somewhere'
    end

    it "should set the url" do
      @uploader.retrieve_from_store('monkey.txt')
      @uploader.url.should == 'http://www.example.com'
    end

    it "should set the identifier" do
      @uploader.retrieve_from_store('monkey.txt')
      @uploader.identifier.should == 'this-is-me'
    end
    
    it "should instruct the storage engine to retrieve the file and store the result" do
      @uploader_class.storage.should_receive(:retrieve!).with(@uploader, 'monkey.txt').and_return(@stored_file)
      @uploader.retrieve_from_store('monkey.txt')
      @uploader.file.should == @stored_file
    end
    
    it "should not overwrite a file that has already been cached" do
      @uploader.retrieve_from_cache!('20071201-1234-345-2255/test.jpeg')
      @uploader.retrieve_from_store('bork.txt')
      @uploader.current_path.should == public_path('uploads/tmp/20071201-1234-345-2255/test.jpeg')
    end
  end
  
  describe 'with a version' do
    before do
      @uploader_class.version(:thumb)
    end
    
    describe '#cache!' do

      before do
        Stapler::Uploader.stub!(:generate_cache_id).and_return('20071201-1234-345-2255')
      end

      it "should suffix the version's store_dir" do
        @uploader.cache!(File.open(file_path('test.jpg')))
        @uploader.store_dir.should == 'public/uploads'
        @uploader.thumb.store_dir.should == 'public/uploads/thumb'
      end
      
      it "should move it to the tmp dir with the filename prefixed" do
        @uploader.cache!(File.open(file_path('test.jpg')))
        @uploader.current_path.should == public_path('uploads/tmp/20071201-1234-345-2255/test.jpg')
        @uploader.thumb.current_path.should == public_path('uploads/tmp/20071201-1234-345-2255/thumb_test.jpg')
        @uploader.file.exists?.should be_true
        @uploader.thumb.file.exists?.should be_true
      end
    end

    describe '#retrieve_from_cache!' do
      it "should set the path to the tmp dir" do
        @uploader.retrieve_from_cache!('20071201-1234-345-2255/test.jpg')
        @uploader.current_path.should == public_path('uploads/tmp/20071201-1234-345-2255/test.jpg')
        @uploader.thumb.current_path.should == public_path('uploads/tmp/20071201-1234-345-2255/thumb_test.jpg')
      end
    
      it "should suffix the version's store_dir" do
        @uploader.retrieve_from_cache!('20071201-1234-345-2255/test.jpg')
        @uploader.store_dir.should == 'public/uploads'
        @uploader.thumb.store_dir.should == 'public/uploads/thumb'
      end
    end
    
    describe '#store!' do
      before do
        @file = File.open(file_path('test.jpg'))

        @stored_file = mock('a stored file')
        @stored_file.stub!(:path).and_return('/path/to/somewhere')
        @stored_file.stub!(:url).and_return('http://www.example.com')

        @uploader_class.storage.stub!(:store!).and_return(@stored_file)
      end
      
      after do
        Stapler.config[:use_cache] = true
      end
      
      it "should set the current path for the version" do
        pending "find a decent way to spec this"
        @uploader.store!(@file)
        @uploader.current_path.should == '/path/to/somewhere'
        @uploader.thumb.current_path.should == '/path/to/somewhere'
      end
      
      it "should set the url" do
        pending "find a decent way to spec this"
        @uploader.store!(@file)
        @uploader.url.should == 'http://www.example.com'
      end
    
      it "should, if a file is given as argument, suffix the version's store_dir" do
        @uploader.store!(@file)
        @uploader.store_dir.should == 'public/uploads'
        @uploader.thumb.store_dir.should == 'public/uploads/thumb'
      end
    
      it "should, if a files is given as an argument and use_cache is false, suffix the version's store_dir" do
        Stapler.config[:use_cache] = false
        @uploader.store!(@file)
        @uploader.store_dir.should == 'public/uploads'
        @uploader.thumb.store_dir.should == 'public/uploads/thumb'
      end
    
    end
    
    describe '#retrieve_from_store!' do
      before do
        @stored_file = mock('a stored file')
        @stored_file.stub!(:path).and_return('/path/to/somewhere')
        @stored_file.stub!(:url).and_return('http://www.example.com')
        
        @uploader_class.storage.stub!(:retrieve!).and_return(@stored_file)
      end
    
      it "should set the current path" do
        @uploader.retrieve_from_store!('monkey.txt')
        @uploader.current_path.should == '/path/to/somewhere'
      end
      
      it "should set the url" do
        @uploader.retrieve_from_store!('monkey.txt')
        @uploader.url.should == 'http://www.example.com'
      end
      
      it "should pass the identifier to the storage engine" do
        @uploader_class.storage.should_receive(:retrieve!).with(@uploader, 'monkey.txt').and_return(@stored_file)
        @uploader.retrieve_from_store!('monkey.txt')
        @uploader.file.should == @stored_file
      end
      
      it "should not set the filename" do
        @uploader.retrieve_from_store!('monkey.txt')
        @uploader.filename.should be_nil
      end
    end
  end
  
  describe 'with an overridden, reversing, filename' do
    before do
      @uploader_class.class_eval do
        def filename
          super.reverse unless super.blank?
        end
      end
    end
    
    describe '#cache!' do

      before do
        Stapler::Uploader.stub!(:generate_cache_id).and_return('20071201-1234-345-2255')
      end

      it "should set the filename to the file's reversed filename" do
        @uploader.cache!(File.open(file_path('test.jpg')))
        @uploader.filename.should == "gpj.tset"
      end
      
      it "should move it to the tmp dir with the filename unreversed" do
        @uploader.cache!(File.open(file_path('test.jpg')))
        @uploader.current_path.should == public_path('uploads/tmp/20071201-1234-345-2255/test.jpg')
        @uploader.file.exists?.should be_true
      end
    end

    describe '#retrieve_from_cache!' do
      it "should set the path to the tmp dir" do
        @uploader.retrieve_from_cache!('20071201-1234-345-2255/test.jpg')
        @uploader.current_path.should == public_path('uploads/tmp/20071201-1234-345-2255/test.jpg')
      end
    
      it "should set the filename to the reversed name of the file" do
        @uploader.retrieve_from_cache!('20071201-1234-345-2255/test.jpg')
        @uploader.filename.should == "gpj.tset"
      end
    end
    
    describe '#store!' do
      before do
        @file = File.open(file_path('test.jpg'))

        @stored_file = mock('a stored file')
        @stored_file.stub!(:path).and_return('/path/to/somewhere')
        @stored_file.stub!(:url).and_return('http://www.example.com')

        @uploader_class.storage.stub!(:store!).and_return(@stored_file)
      end
      
      after do
        Stapler.config[:use_cache] = true
      end
      
      it "should set the current path" do
        @uploader.store!(@file)
        @uploader.current_path.should == '/path/to/somewhere'
      end
      
      it "should set the url" do
        @uploader.store!(@file)
        @uploader.url.should == 'http://www.example.com'
      end
    
      it "should, if a file is given as argument, reverse the filename" do
        @uploader.store!(@file)
        @uploader.filename.should == 'gpj.tset'
      end
    
      it "should, if a files is given as an argument and use_cache is false, reverse the filename" do
        Stapler.config[:use_cache] = false
        @uploader.store!(@file)
        @uploader.filename.should == 'gpj.tset'
      end
    
    end
    
    describe '#retrieve_from_store!' do
      before do
        @stored_file = mock('a stored file')
        @stored_file.stub!(:path).and_return('/path/to/somewhere')
        @stored_file.stub!(:url).and_return('http://www.example.com')
        
        @uploader_class.storage.stub!(:retrieve!).and_return(@stored_file)
      end
    
      it "should set the current path" do
        @uploader.retrieve_from_store!('monkey.txt')
        @uploader.current_path.should == '/path/to/somewhere'
      end
      
      it "should set the url" do
        @uploader.retrieve_from_store!('monkey.txt')
        @uploader.url.should == 'http://www.example.com'
      end
      
      it "should pass the identifier to the storage engine" do
        @uploader_class.storage.should_receive(:retrieve!).with(@uploader, 'monkey.txt').and_return(@stored_file)
        @uploader.retrieve_from_store!('monkey.txt')
        @uploader.file.should == @stored_file
      end
      
      it "should not set the filename" do
        @uploader.retrieve_from_store!('monkey.txt')
        @uploader.filename.should be_nil
      end
    end
    
  end
  
end