def fog_tests(fog_credentials)
  describe CarrierWave::Storage::Fog do
    describe fog_credentials[:provider] do

      shared_examples_for "#{fog_credentials[:provider]} storage" do

        before do
          CarrierWave.configure do |config|
            config.reset_config
            config.fog_attributes      = {}
            config.fog_credentials     = fog_credentials
            config.fog_directory       = CARRIERWAVE_DIRECTORY
            config.fog_public          = true
            config.fog_use_ssl_for_aws = true
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

        describe '#cache_stored_file!' do
          it "should cache_stored_file! after store!" do
            uploader = @uploader.new
            uploader.store!(@file)
            lambda{ uploader.cache_stored_file! }.should_not raise_error
          end
        end

        describe '#store!' do
          before do
            @uploader.stub!(:store_path).and_return('uploads/test+.jpg')
            @fog_file = @storage.store!(@file)
          end

          it "should upload the file" do
            @directory.files.get('uploads/test+.jpg').body.should == 'this is stuff'
          end

          it "should have a path" do
            @fog_file.path.should == 'uploads/test+.jpg'
          end

          it "should have a content_type" do
            @fog_file.content_type.should == 'image/jpeg'
            @directory.files.get('uploads/test+.jpg').content_type.should == 'image/jpeg'
          end

          it "should have an extension" do
            @fog_file.extension.should == "jpg"
          end

          context "without asset_host" do
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

            it "should use a subdomain URL for AWS if the directory is a valid subdomain" do
              if @provider == 'AWS'
                @uploader.stub(:fog_directory).and_return('assets.site.com')
                @fog_file.public_url.should include('https://assets.site.com.s3.amazonaws.com')
              end
            end

            it "should not use a subdomain URL for AWS if the directory is not a valid subdomain" do
              if @provider == 'AWS'
                @uploader.stub(:fog_directory).and_return('SiteAssets')
                @fog_file.public_url.should include('https://s3.amazonaws.com/SiteAssets')
              end
            end

            it "should use https as a default protocol" do
              if @provider == 'AWS'
                @fog_file.public_url.should start_with 'https://'
              end
            end

            it "should use https as a default protocol" do
              if @provider == 'AWS'
                @uploader.stub(:fog_use_ssl_for_aws).and_return(false)
                @fog_file.public_url.should start_with 'http://'
              end
            end
          end

          context "with asset_host" do
            before { @uploader.stub(:asset_host).and_return(asset_host) }

            context "when a asset_host is a proc" do

              let(:asset_host) { proc { "http://foo.bar" } }

              describe "args passed to proc" do
                let(:asset_host) { proc { |storage| storage.should be_instance_of ::CarrierWave::Storage::Fog::File } }

                it "should be the uploader" do
                  @fog_file.public_url
                end
              end

              it "should have a asset_host rooted public_url" do
                @fog_file.public_url.should == 'http://foo.bar/uploads/test%2B.jpg'
              end

              it "should have a asset_host rooted url" do
                @fog_file.url.should == 'http://foo.bar/uploads/test%2B.jpg'
              end

              it "should always have the same asset_host rooted url" do
                @fog_file.url.should == 'http://foo.bar/uploads/test%2B.jpg'
                @fog_file.url.should == 'http://foo.bar/uploads/test%2B.jpg'
              end

              it 'should retrieve file name' do
                @fog_file.filename.should == 'test+.jpg'
              end
            end

            context "when a string" do
              let(:asset_host) { "http://foo.bar" }

              it "should have a asset_host rooted public_url" do
                @fog_file.public_url.should == 'http://foo.bar/uploads/test%2B.jpg'
              end

              it "should have a asset_host rooted url" do
                @fog_file.url.should == 'http://foo.bar/uploads/test%2B.jpg'
              end

              it "should always have the same asset_host rooted url" do
                @fog_file.url.should == 'http://foo.bar/uploads/test%2B.jpg'
                @fog_file.url.should == 'http://foo.bar/uploads/test%2B.jpg'
              end
            end
          end

          it "should return filesize" do
            @fog_file.size.should == 13
          end

          it "should be deletable" do
            @fog_file.delete
            @directory.files.head('uploads/test+.jpg').should == nil
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
              if ['AWS', 'Rackspace', 'Google'].include?(@provider)
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
