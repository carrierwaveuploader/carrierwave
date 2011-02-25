def fog_tests(fog_credentials)
  describe CarrierWave::Storage::Fog do
    describe fog_credentials[:provider] do
      before do
        CarrierWave.configure do |config|
          config.reset_config
          config.fog_attributes  = {}
          config.fog_credentials = fog_credentials
          config.fog_directory   = ENV['CARRIERWAVE_DIRECTORY']
          config.fog_host        = nil
          config.fog_public      = true
        end

        eval <<-RUBY
class FogSpec#{fog_credentials[:provider]}Uploader < CarrierWave::Uploader::Base
  storage :fog
end
        RUBY

        # @uploader = FogSpecUploader.new
        @uploader = eval("FogSpec#{fog_credentials[:provider]}Uploader")
        @uploader.stub!(:store_path).and_return('uploads/bar.txt')

        @storage = CarrierWave::Storage::Fog.new(@uploader)
        @directory = @storage.connection.directories.new(:key => ENV['CARRIERWAVE_DIRECTORY'])
        @file = CarrierWave::SanitizedFile.new(file_path('test.jpg'))
      end

      describe '#store!' do
        before do
          @uploader.stub!(:store_path).and_return('uploads/bar.txt')
          @fog_file = @storage.store!(@file)
        end

        it "should upload the file" do
          @directory.files.get('uploads/bar.txt').body.should == 'this is stuff'
        end

        it "should have a path" do
          @fog_file.path.should == 'uploads/bar.txt'
        end

        context "without fog_host" do
          it "should have a public_url" do
            pending if fog_credentials[:provider] == 'Local'
            @fog_file.public_url.should_not be_nil
          end

          it "should have a url" do
            pending if fog_credentials[:provider] == 'Local'
            @fog_file.url.should_not be_nil
          end
        end

        context "with fog_host" do
          it "should have a fog_host rooted public_url" do
            @uploader.stub!(:fog_host).and_return('http://foo.bar')
            @fog_file.public_url.should == 'http://foo.bar/uploads/bar.txt'
          end

          it "should have a fog_host rooted url" do
            @uploader.stub!(:fog_host).and_return('http://foo.bar')
            @fog_file.url.should == 'http://foo.bar/uploads/bar.txt'
          end

          it "should always have the same fog_host rooted url" do
            @uploader.stub!(:fog_host).and_return('http://foo.bar')
            @fog_file.url.should == 'http://foo.bar/uploads/bar.txt'
            @fog_file.url.should == 'http://foo.bar/uploads/bar.txt'
          end
        end

        it "should return filesize" do
          @fog_file.size.should == 13
        end

        it "should be deletable" do
          @fog_file.delete
          @directory.files.head('uploads/bar.txt').should == nil
        end
      end

      describe '#retrieve!' do
        before do
          @directory.files.create(:key => 'uploads/bar.txt', :body => 'A test, 1234', :public => true)
          @uploader.stub!(:store_path).with('bar.txt').and_return('uploads/bar.txt')
          @fog_file = @storage.retrieve!('bar.txt')
        end

        it "should retrieve the file contents" do
          @fog_file.read.chomp.should == "A test, 1234"
        end

        it "should have a path" do
          @fog_file.path.should == 'uploads/bar.txt'
        end

        it "should have a public url" do
          pending if fog_credentials[:provider] == 'Local'
          @fog_file.public_url.should_not be_nil
        end

        it "should return filesize" do
          @fog_file.size.should == 12
        end

        it "should be deletable" do
          @fog_file.delete
          @directory.files.head('uploads/bar.txt').should == nil
        end
      end

      describe 'fog_public' do
        after do
          @directory.files.get('uploads/bar.txt').destroy
        end

        context "true" do
          before do
            @fog_file = @storage.store!(@file)
          end

          it "should be available at public URL" do
            pending if Fog.mocking? || fog_credentials[:provider] == 'Local'
            open(@fog_file.public_url).read.should == 'this is stuff'
          end
        end

        context "false" do
          before do
            @uploader.stub!(:fog_public).and_return(false)
            @fog_file = @storage.store!(@file)
          end

          it "should not be available at public URL" do
            pending if fog_credentials[:provider] == 'Local'
            pending if fog_credentials[:provider] == 'Rackspace'
            @fog_file.public_url.should be_nil
          end
        end
      end
    end
  end
end