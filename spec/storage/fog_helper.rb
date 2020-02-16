def fog_tests(fog_credentials)
  describe CarrierWave::Storage::Fog do
    shared_examples_for "#{fog_credentials[:provider]} storage" do

      before do
        WebMock.disable! unless Fog.mocking?
        CarrierWave.configure do |config|
          config.reset_config
          config.fog_attributes = {}
          config.fog_credentials = fog_credentials
          config.fog_directory = CARRIERWAVE_DIRECTORY
          config.fog_public = true
          config.fog_use_ssl_for_aws = true
          config.cache_storage = :fog
        end

        eval <<-RUBY
class FogSpec#{fog_credentials[:provider]}Uploader < CarrierWave::Uploader::Base
storage :fog
end
        RUBY

        @provider = fog_credentials[:provider]

        # @uploader = FogSpecUploader.new
        @uploader = eval("FogSpec#{@provider}Uploader")
        allow(@uploader).to receive(:store_path).and_return('uploads/test.jpg')

        @storage = CarrierWave::Storage::Fog.new(@uploader)
        @directory = @storage.connection.directories.get(CARRIERWAVE_DIRECTORY) || @storage.connection.directories.create(:key => CARRIERWAVE_DIRECTORY, :public => true)
      end

      after do
        CarrierWave.configure do |config|
          config.reset_config
        end
        WebMock.enable! unless Fog.mocking?
      end

      describe '#cache_stored_file!' do
        it "should cache_stored_file! after store!" do
          uploader = @uploader.new
          uploader.store!(file)
          expect { uploader.cache_stored_file! }.not_to raise_error
        end

        it "should create local file for processing" do
          @uploader.class_eval do
            def check_file
              raise unless File.exists?(file.path)
            end
            process :check_file
          end
          uploader = @uploader.new
          uploader.store!(file)
          uploader.cache_stored_file!
        end
      end

      context '#acl_header' do
        let(:store_path) { 'uploads/test+.jpg' }

        before do
          allow(@uploader).to receive(:store_path).and_return(store_path)
        end

        it 'includes acl_header when necessary' do
          if file.is_a?(CarrierWave::Storage::Fog::File)
            if @provider == 'AWS'
              expect(@storage.connection).to receive(:copy_object)
                                              .with(anything, anything, anything, anything, { "x-amz-acl"=>"public-read" }).and_call_original
            else
              expect(@storage.connection).to receive(:copy_object)
                                              .with(anything, anything, anything, anything, {}).and_call_original
            end
          end

          @storage.store!(file)
        end
      end

      describe '#store!' do
        let(:store_path) { 'uploads/test+.jpg' }

        context 'when file is ::File' do
          before do
            allow(@uploader).to receive(:store_path).and_return(store_path)
            @fog_file = @storage.store!(file)
          end

          it "should upload the file" do
            # reading the file after upload should return the body, not a closed tempfile
            expect(@fog_file.read).to eq('this is stuff')
            # make sure it actually uploaded to the service, too
            expect(@directory.files.get(store_path).body).to eq('this is stuff')
          end

          it "should have a path" do
            expect(@fog_file.path).to eq(store_path)
          end

          it "should have a content_type" do
            expect(@fog_file.content_type).to eq(file.content_type)
            expect(@directory.files.get(store_path).content_type).to eq(file.content_type)
          end

          it "should have an extension" do
            expect(@fog_file.extension).to eq("jpg")
          end

          context "without asset_host" do
            it "should have a public_url" do
              unless fog_credentials[:provider] == 'Local'
                expect(@fog_file.public_url).not_to be_nil
              end
            end

            it "should have a url" do
              unless fog_credentials[:provider] == 'Local'
                expect(@fog_file.url).not_to be_nil
              end
            end

            context "directory is a valid subdomain" do
              before do
                allow(@uploader).to receive(:fog_directory).and_return('assets-site-com')
              end

              it "should use a subdomain URL for AWS" do
                if @provider == 'AWS'
                  expect(@fog_file.public_url).to include('https://assets-site-com.s3.amazonaws.com')
                end
              end

              it "should use accelerate domain if fog_aws_accelerate is true" do
                if @provider == 'AWS'
                  allow(@uploader).to receive(:fog_aws_accelerate).and_return(true)
                  expect(@fog_file.public_url).to include('https://assets-site-com.s3-accelerate.amazonaws.com')
                end
              end
            end

            it "should not use a subdomain URL for AWS if the directory is not a valid subdomain" do
              if @provider == 'AWS'
                allow(@uploader).to receive(:fog_directory).and_return('SiteAssets')
                expect(@fog_file.public_url).to include('https://s3.amazonaws.com/SiteAssets')
              end
            end

            it "should not use a subdomain URL for AWS if https && the directory is not accessible over https as a virtual hosted bucket" do
              if @provider == 'AWS'
                allow(@uploader).to receive(:fog_use_ssl_for_aws).and_return(true)
                allow(@uploader).to receive(:fog_directory).and_return('foo.bar')
                expect(@fog_file.public_url).to include('https://s3.amazonaws.com/foo.bar')
              end
            end

            it "should use a subdomain URL for AWS if http && the directory is not accessible over https as a virtual hosted bucket" do
              if @provider == 'AWS'
                allow(@uploader).to receive(:fog_use_ssl_for_aws).and_return(false)
                allow(@uploader).to receive(:fog_directory).and_return('foo.bar')
                expect(@fog_file.public_url).to include('http://foo.bar.s3.amazonaws.com/')
              end
            end

            {
              nil            => 's3.amazonaws.com',
              'us-east-1'    => 's3.amazonaws.com',
              'us-east-2'    => 's3.us-east-2.amazonaws.com',
              'eu-central-1' => 's3.eu-central-1.amazonaws.com'
            }.each do |region, expected_host|
              it "should use a #{expected_host} hostname when using path style for access #{region} region" do
                if @provider == 'AWS'
                  allow(@uploader).to receive(:fog_use_ssl_for_aws).and_return(true)
                  allow(@uploader).to receive(:fog_directory).and_return('foo.bar')

                  allow(@uploader).to receive(:fog_credentials).and_return(@uploader.fog_credentials.merge(region: region))

                  expect(@fog_file.public_url).to include("https://#{expected_host}/foo.bar")
                end
              end
            end

            it "should use https as a default protocol" do
              if @provider == 'AWS'
                expect(@fog_file.public_url).to start_with 'https://'
              end
            end

            it "should use https as a default protocol" do
              if @provider == 'AWS'
                allow(@uploader).to receive(:fog_use_ssl_for_aws).and_return(false)
                expect(@fog_file.public_url).to start_with 'http://'
              end
            end

            it "should use the google public url if available" do
              if @provider == 'Google'
                allow(@uploader).to receive(:fog_directory).and_return('SiteAssets')
                expect(@fog_file.public_url).to include('https://storage.googleapis.com/SiteAssets')
              end
            end
          end

          context "with asset_host" do
            before { allow(@uploader).to receive(:asset_host).and_return(asset_host) }

            context "when a asset_host is a proc" do

              let(:asset_host) { proc { "http://foo.bar" } }

              describe "args passed to proc" do
                let(:asset_host) { proc { |storage| expect(storage).to be_instance_of ::CarrierWave::Storage::Fog::File } }

                it "should be the uploader" do
                  @fog_file.public_url
                end
              end

              it "should have a asset_host rooted public_url" do
                expect(@fog_file.public_url).to eq('http://foo.bar/uploads/test%2B.jpg')
              end

              it "should have a asset_host rooted url" do
                expect(@fog_file.url).to eq('http://foo.bar/uploads/test%2B.jpg')
              end

              it "should always have the same asset_host rooted url" do
                expect(@fog_file.url).to eq('http://foo.bar/uploads/test%2B.jpg')
                expect(@fog_file.url).to eq('http://foo.bar/uploads/test%2B.jpg')
              end

              it 'should retrieve file name' do
                expect(@fog_file.filename).to eq('test+.jpg')
              end
            end

            context "when a string" do
              let(:asset_host) { "http://foo.bar" }

              it "should have a asset_host rooted public_url" do
                expect(@fog_file.public_url).to eq('http://foo.bar/uploads/test%2B.jpg')
              end

              it "should have a asset_host rooted url" do
                expect(@fog_file.url).to eq('http://foo.bar/uploads/test%2B.jpg')
              end

              it "should always have the same asset_host rooted url" do
                expect(@fog_file.url).to eq('http://foo.bar/uploads/test%2B.jpg')
                expect(@fog_file.url).to eq('http://foo.bar/uploads/test%2B.jpg')
              end
            end

          end

          context "without extension" do

            let(:store_path) { 'uploads/test' }

            it "should have no extension" do
              expect(@fog_file.extension).to be_nil
            end

          end

          it "should return filesize" do
            expect(@fog_file.size).to eq(13)
          end

          it "should be deletable" do
            @fog_file.delete
            expect(@directory.files.head(store_path)).to eq(nil)
          end

          context "when the file has been deleted" do
            before { @fog_file.delete }

            it "should not error getting the file size" do
              expect { @fog_file.size }.not_to raise_error
            end

            it "should not error getting the content type" do
              expect { @fog_file.content_type }.not_to raise_error
            end

            it "should not return false for content type" do
              expect(@fog_file.content_type).not_to be false
            end

            it "should let #exists? be false" do
              expect(@fog_file.exists?).to be false
            end
          end
        end

        context 'when file is ::StringIO' do
          let(:file) do
            CarrierWave::SanitizedFile.new(
              :tempfile => StringIO.new('Test StringIO texts'),
              :filename => 'test.jpg',
              :content_type => 'image/jpeg'
            )
          end

          before do
            allow(@uploader).to receive(:store_path).and_return(store_path)
            @fog_file = @storage.store!(file)
          end

          it "should upload the file" do
            # reading the file after upload should return the body, not a closed tempfile
            expect(@fog_file.read).to eq('Test StringIO texts')
            # make sure it actually uploaded to the service, too
            expect(@directory.files.get(store_path).body).to eq('Test StringIO texts')
          end
        end
      end

      describe '#retrieve!' do
        before do
          @directory.files.create(:key => 'uploads/test.jpg', :body => 'A test, 1234', :public => true)
          allow(@uploader).to receive(:store_path).with('test.jpg').and_return('uploads/test.jpg')
          @fog_file = @storage.retrieve!('test.jpg')
        end

        it "should retrieve the file contents" do
          expect(@fog_file.read.chomp).to eq("A test, 1234")
        end

        it "should have a path" do
          expect(@fog_file.path).to eq('uploads/test.jpg')
        end

        it "should have a public url" do
          unless fog_credentials[:provider] == 'Local'
            expect(@fog_file.public_url).not_to be_nil
          end
        end

        it "should return filesize" do
          expect(@fog_file.size).to eq(12)
        end

        it "should be deletable" do
          @fog_file.delete
          expect(@directory.files.head('uploads/test.jpg')).to eq(nil)
        end
      end

      describe '#cache!' do
        before do
          allow(@uploader).to receive(:cache_path).and_return('uploads/tmp/test+.jpg')
          @fog_file = @storage.cache!(file)
        end

        it "should upload the file", focus: true do
          expect(@directory.files.get('uploads/tmp/test+.jpg').body).to eq('this is stuff')
        end

        it 'should preserve content type' do
          expect(@fog_file.content_type).to eq(file.content_type)
        end
      end

      describe '#retrieve_from_cache!' do
        before do
          @directory.files.create(:key => 'uploads/tmp/test.jpg', :body => 'A test, 1234', :public => true)
          allow(@uploader).to receive(:cache_path).with('test.jpg').and_return('uploads/tmp/test.jpg')
          @fog_file = @storage.retrieve_from_cache!('test.jpg')
        end

        it "should retrieve the file contents" do
          expect(@fog_file.read.chomp).to eq("A test, 1234")
        end
      end

      describe '#delete_dir' do
        it "should do nothing" do
          expect(running{ @storage.delete_dir!('foobar') }).not_to raise_error
        end
      end

      describe '#clean_cache!' do
        let(:today) { Time.now.round }
        let(:five_days_ago) { today.ago(5.days) }
        let(:three_days_ago) { today.ago(3.days) }
        let(:yesterday) { today.yesterday }
        before do
          # clean up
          @directory.files.each{|file| file.destroy }
          # We can't use simple time freezing because of AWS request time check
          [five_days_ago, three_days_ago, yesterday, (today - 1.minute)].each do |created_date|
            key = nil
            Timecop.freeze created_date do
              key = "uploads/tmp/#{CarrierWave.generate_cache_id}/test.jpg"
            end
            @directory.files.create(:key => key, :body => 'A test, 1234', :public => true)
          end
        end

        it "should clear all files older than now in the default cache directory" do
          Timecop.freeze(today) do
            @uploader.clean_cached_files!(0)
          end
          expect(@directory.files.all(:prefix => 'uploads/tmp').size).to eq(0)
        end

        it "should clear all files older than, by defaul, 24 hours in the default cache directory" do
          Timecop.freeze(today) do
            @uploader.clean_cached_files!
          end
          expect(@directory.files.all(:prefix => 'uploads/tmp').size).to eq(2)
        end

        it "should permit to set since how many seconds delete the cached files" do
          Timecop.freeze(today) do
            @uploader.clean_cached_files!(4.days)
          end
          expect(@directory.files.all(:prefix => 'uploads/tmp').size).to eq(3)
        end

        it "should be aliased on the CarrierWave module" do
          Timecop.freeze(today) do
            CarrierWave.clean_cached_files!
          end
          expect(@directory.files.all(:prefix => 'uploads/tmp').size).to eq(2)
        end

        it "cleans a directory named using old format of cache id" do
          @directory.files.create(:key => "uploads/tmp/#{yesterday.utc.to_i}-100-1234/test.jpg", :body => 'A test, 1234', :public => true)
          Timecop.freeze(today) do
            @uploader.clean_cached_files!(0)
          end
          expect(@directory.files.all(:prefix => 'uploads/tmp').size).to eq(0)
        end
      end

      describe 'fog_public' do

        context "true" do
          before do
            directory_key = "#{CARRIERWAVE_DIRECTORY}public"
            @directory = @storage.connection.directories.create(:key => directory_key, :public => true)
            allow(@uploader).to receive(:fog_directory).and_return(directory_key)
            allow(@uploader).to receive(:store_path).and_return('uploads/public.txt')
            @fog_file = @storage.store!(file)
          end

          after do
            @directory.files.new(:key => 'uploads/public.txt').destroy
            @directory.files.new(:key => 'test.jpg').destroy
            @directory.destroy
          end

          it "should be available at public URL" do
            unless Fog.mocking? || fog_credentials[:provider] == 'Local'
              expect(open(@fog_file.public_url).read).to eq('this is stuff')
            end
          end
        end

        context "false" do
          before do
            directory_key = "#{CARRIERWAVE_DIRECTORY}private"
            @directory = @storage.connection.directories.create(:key => directory_key, :public => true)
            allow(@uploader).to receive(:fog_directory).and_return(directory_key)
            allow(@uploader).to receive(:fog_public).and_return(false)
            allow(@uploader).to receive(:store_path).and_return('uploads/private.txt')
            @fog_file = @storage.store!(file)
          end

          after do
            @directory.files.new(:key => 'uploads/private.txt').destroy
            @directory.files.new(:key => 'test.jpg').destroy
            @directory.destroy
          end

          it "should not be available at public URL" do
            unless Fog.mocking? || fog_credentials[:provider] == 'Local'
              expect(running{ open(@fog_file.public_url) }).to raise_error OpenURI::HTTPError
            end
          end

          it "should have an authenticated_url" do
            if ['AWS', 'Rackspace', 'Google', 'OpenStack', 'AzureRM', 'Aliyun', 'backblaze'].include?(@provider)
              expect(@fog_file.authenticated_url).not_to be_nil
            end
          end

          it "should have an custom authenticated_url" do
            if ['AWS', 'Rackspace', 'Google', 'OpenStack', 'AzureRM'].include?(@provider)
              timestamp = ::Fog::Time.now + 999
              if @provider == "AWS"
                expect(@fog_file.authenticated_url({expire_at: timestamp })).to include("Expires=999&")
              elsif @provider == "Google"
                expect(@fog_file.authenticated_url({expire_at: timestamp })).to include("Expires=#{timestamp.to_i}")
              end
            end
          end

          it 'should generate correct filename' do
            expect(@fog_file.filename).to eq('private.txt')
          end

          it "should handle query params" do
            if ['AWS', 'Google'].include?(@provider)
              url = @fog_file.url(:query => {"response-content-disposition" => "attachment"})
              expect(url).to match(/response-content-disposition=attachment/)
              unless Fog.mocking?
                # Workaround for S3 SignatureDoesNotMatch issue
                #   https://github.com/excon/excon/issues/475
                Excon.defaults[:omit_default_port] = true
                response = Excon.get(url)
                expect(response.status).to be 200
                expect(response.headers["Content-Disposition"]).to eq("attachment")
              end
            end
          end

          it "should not use #file to get signed url" do
            if ['AWS', 'Google'].include?(@provider)
              allow(@fog_file).to receive(:file).and_return(nil)
              expect { @fog_file.url }.not_to raise_error
            end
          end
        end
      end

    end

    describe "with a valid Hash" do
      let(:file) do
        CarrierWave::SanitizedFile.new(
          :tempfile => stub_merb_tempfile('test.jpg'),
          :filename => 'test.jpg',
          :content_type => 'image/jpeg'
        )
      end

      it_should_behave_like "#{fog_credentials[:provider]} storage"
    end

    describe "with a valid Tempfile" do
      let(:file) do
        CarrierWave::SanitizedFile.new(stub_tempfile('test.jpg', 'image/jpeg'))
      end

      it_should_behave_like "#{fog_credentials[:provider]} storage"
    end

    describe "with a valid StringIO" do
      let(:file) do
        CarrierWave::SanitizedFile.new(stub_stringio('test.jpg', 'image/jpeg'))
      end

      it_should_behave_like "#{fog_credentials[:provider]} storage"
    end

    describe "with a valid File object" do
      let(:file) do
        CarrierWave::SanitizedFile.new(stub_file('test.jpg', 'image/jpeg'))
      end

      it_should_behave_like "#{fog_credentials[:provider]} storage"

    end

    describe "with a valid File object with an explicit content type" do
      let(:file) do
        CarrierWave::SanitizedFile.new(stub_file('test.jpg', 'image/jpeg')).tap do |f|
          f.content_type = 'image/jpg'
        end
      end

      it_should_behave_like "#{fog_credentials[:provider]} storage"
    end

    describe "with a valid path" do
      let(:file) do
        CarrierWave::SanitizedFile.new(file_path('test.jpg'))
      end

      it_should_behave_like "#{fog_credentials[:provider]} storage"
    end

    describe "with a valid Pathname" do
      let(:file) do
        CarrierWave::SanitizedFile.new(Pathname.new(file_path('test.jpg')))
      end

      it_should_behave_like "#{fog_credentials[:provider]} storage"
    end

    describe "with a CarrierWave::Storage::Fog::File" do
      let(:file) do
        CarrierWave::Storage::Fog::File.new(@uploader, @storage, 'test.jpg').
          tap{|file| file.store(CarrierWave::SanitizedFile.new(
            :tempfile => StringIO.new('this is stuff'), :content_type => 'image/jpeg')) }
      end

      it_should_behave_like "#{fog_credentials[:provider]} storage"
    end

  end
end
