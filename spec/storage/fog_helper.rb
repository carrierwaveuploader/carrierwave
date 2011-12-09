def fog_tests(fog_credentials)
  describe CarrierWave::Storage::Fog do
    describe fog_credentials[:provider] do

      shared_examples_for "#{fog_credentials[:provider]} storage" do

        before do
          CarrierWave.configure do |config|
            config.reset_config
            config.fog_attributes  = {}
            config.fog_credentials = fog_credentials
            config.fog_directory   = CARRIERWAVE_DIRECTORY
            config.fog_host        = nil
            config.fog_public      = true
          end

          eval <<-RUBY
class FogSpec#{fog_credentials[:provider]}Uploader < CarrierWave::Uploader::Base
  storage :fog
end
          RUBY

          @provider = fog_credentials[:provider]

          # @uploader = FogSpecUploader.new
          @uploader = eval("FogSpec#{@provider}Uploader")
          @uploader.stub!(:store_path).and_return('uploads/test.jpg')

          @storage = CarrierWave::Storage::Fog.new(@uploader)
          @directory = @storage.connection.directories.get(CARRIERWAVE_DIRECTORY) || @storage.connection.directories.create(:key => CARRIERWAVE_DIRECTORY, :public => true)
        end

        describe '#store!' do
          before do
            @uploader.stub!(:store_path).and_return('uploads/test.jpg')
            @fog_file = @storage.store!(@file)
          end

          it "should upload the file" do
            @directory.files.get('uploads/test.jpg').body.should == 'this is stuff'
          end

          it "should have a path" do
            @fog_file.path.should == 'uploads/test.jpg'
          end

          it "should have a content_type" do
            @fog_file.content_type.should == 'image/jpeg'
            @directory.files.get('uploads/test.jpg').content_type.should == 'image/jpeg'
          end

          context "without fog_host" do
            it "should have a public_url" do
              unless fog_credentials[:provider] == 'Local'
                @fog_file.public_url.should_not be_nil
              end
            end

            it "should have a url" do
              unless fog_credentials[:provider] == 'Local'
                @fog_file.url.should_not be_nil
              end
            end
          end

          context "with fog_host" do
            it "should have a fog_host rooted public_url" do
              @uploader.stub!(:fog_host).and_return('http://foo.bar')
              @fog_file.public_url.should == 'http://foo.bar/uploads/test.jpg'
            end

            it "should have a fog_host rooted url" do
              @uploader.stub!(:fog_host).and_return('http://foo.bar')
              @fog_file.url.should == 'http://foo.bar/uploads/test.jpg'
            end

            it "should always have the same fog_host rooted url" do
              @uploader.stub!(:fog_host).and_return('http://foo.bar')
              @fog_file.url.should == 'http://foo.bar/uploads/test.jpg'
              @fog_file.url.should == 'http://foo.bar/uploads/test.jpg'
            end
          end

          it "should return filesize" do
            @fog_file.size.should == 13
          end

          it "should be deletable" do
            @fog_file.delete
            @directory.files.head('uploads/test.jpg').should == nil
          end
        end

        describe '#retrieve!' do
          before do
            @directory.files.create(:key => 'uploads/test.jpg', :body => 'A test, 1234', :public => true)
            @uploader.stub!(:store_path).with('test.jpg').and_return('uploads/test.jpg')
            @fog_file = @storage.retrieve!('test.jpg')
          end

          it "should retrieve the file contents" do
            @fog_file.read.chomp.should == "A test, 1234"
          end

          it "should have a path" do
            @fog_file.path.should == 'uploads/test.jpg'
          end

          it "should have a public url" do
            unless fog_credentials[:provider] == 'Local'
              @fog_file.public_url.should_not be_nil
            end
          end

          it "should return filesize" do
            @fog_file.size.should == 12
          end

          it "should be deletable" do
            @fog_file.delete
            @directory.files.head('uploads/test.jpg').should == nil
          end
        end

        describe 'fog_public' do

          context "true" do
            before do
              directory_key = "#{CARRIERWAVE_DIRECTORY}public"
              @directory = @storage.connection.directories.create(:key => directory_key, :public => true)
              @uploader.stub!(:fog_directory).and_return(directory_key)
              @uploader.stub!(:store_path).and_return('uploads/public.txt')
              @fog_file = @storage.store!(@file)
            end

            after do
              @directory.files.new(:key => 'uploads/public.txt').destroy
              @directory.destroy
            end

            it "should be available at public URL" do
              unless Fog.mocking? || fog_credentials[:provider] == 'Local'
                open(@fog_file.public_url).read.should == 'this is stuff'
              end
            end
          end

          context "false" do
            before do
              directory_key = "#{CARRIERWAVE_DIRECTORY}private"
              @directory = @storage.connection.directories.create(:key => directory_key, :public => true)
              @uploader.stub!(:fog_directory).and_return(directory_key)
              @uploader.stub!(:fog_public).and_return(false)
              @uploader.stub!(:store_path).and_return('uploads/private.txt')
              @fog_file = @storage.store!(@file)
            end

            after do
              @directory.files.new(:key => 'uploads/private.txt').destroy
              @directory.destroy
            end

            it "should have an authenticated_url" do
              if ['AWS', 'Google'].include?(@provider)
                @fog_file.authenticated_url.should_not be_nil
              end
            end

            it "should handle query params" do
              if @provider == 'AWS' && !Fog.mocking?
                headers = Excon.get(@fog_file.url(:query => {"response-content-disposition" => "attachment"})).headers
                headers["Content-Disposition"].should == "attachment"
              end
            end
          end
        end

        context 'finishing' do
          it "should destroy the directory" do # hack, but after never does what/when I want
            @directory.destroy
          end
        end

      end

    end

    describe "with a valid Hash" do
      before do
        @file = CarrierWave::SanitizedFile.new(
          :tempfile => stub_merb_tempfile('test.jpg'),
          :filename => 'test.jpg',
          :content_type => 'image/jpeg'
        )
      end

      it_should_behave_like "#{fog_credentials[:provider]} storage"
    end

    describe "with a valid Tempfile" do
      before do
        @file = CarrierWave::SanitizedFile.new(stub_tempfile('test.jpg', 'image/jpeg'))
      end

      it_should_behave_like "#{fog_credentials[:provider]} storage"
    end

    describe "with a valid StringIO" do
      before do
        @file = CarrierWave::SanitizedFile.new(stub_stringio('test.jpg', 'image/jpeg'))
      end

      it_should_behave_like "#{fog_credentials[:provider]} storage"
    end

    describe "with a valid File object" do
      before do
        @file = CarrierWave::SanitizedFile.new(stub_file('test.jpg', 'image/jpeg'))
        @file.should_not be_empty
      end

      it_should_behave_like "#{fog_credentials[:provider]} storage"
    end

    describe "with a valid path" do
      before do
        @file = CarrierWave::SanitizedFile.new(file_path('test.jpg'))
        @file.should_not be_empty
      end

      it_should_behave_like "#{fog_credentials[:provider]} storage"
    end

    describe "with a valid Pathname" do
      before do
        @file = CarrierWave::SanitizedFile.new(Pathname.new(file_path('test.jpg')))
        @file.should_not be_empty
      end

      it_should_behave_like "#{fog_credentials[:provider]} storage"
    end

  end
end
