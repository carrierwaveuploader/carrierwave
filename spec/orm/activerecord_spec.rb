require 'spec_helper'
require 'support/activerecord'

describe CarrierWave::ActiveRecord do
  def create_table(name)
    ActiveRecord::Base.connection.create_table(name, force: true) do |t|
      t.column :image, :string
      t.column :images, :json
      t.column :textfile, :string
      t.column :textfiles, :json
      t.column :foo, :string
    end
  end

  def drop_table(name)
    ActiveRecord::Base.connection.drop_table(name)
  end

  def reset_class(class_name)
    Object.send(:remove_const, class_name) rescue nil
    Object.const_set(class_name, Class.new(ActiveRecord::Base))
  end

  before(:all) { create_table("events") }
  after(:all) { drop_table("events") }

  before do
    @uploader = Class.new(CarrierWave::Uploader::Base)
    reset_class("Event")
    @event = Event.new
  end

  after do
    Event.delete_all
  end

  describe '#mount_uploader' do
    before do
      Event.mount_uploader(:image, @uploader)
    end

    describe '#image' do

      it "should return blank uploader when nothing has been assigned" do
        expect(@event.image).to be_blank
      end

      it "should return blank uploader when an empty string has been assigned" do
        @event[:image] = ''
        @event.save!
        @event.reload
        expect(@event.image).to be_blank
      end

      it "should retrieve a file from the storage if a value is stored in the database" do
        @event[:image] = 'test.jpeg'
        @event.save!
        @event.reload
        expect(@event.image).to be_an_instance_of(@uploader)
      end

      it "should set the path to the store dir" do
        @event[:image] = 'test.jpeg'
        @event.save!
        @event.reload
        expect(@event.image.current_path).to eq public_path('uploads/test.jpeg')
      end

      it "should return valid JSON when to_json is called when image is nil" do
        expect(@event[:image]).to be_nil
        hash = JSON.parse(@event.to_json)
        expect(hash.keys).to include("image")
        expect(hash["image"].keys).to include("url")
        expect(hash["image"]["url"]).to be_nil
      end

      it "should return valid JSON when to_json is called when image is present" do
        @event[:image] = 'test.jpeg'
        @event.save!
        @event.reload

        expect(JSON.parse(@event.to_json)["image"]).to eq({"url" => "/uploads/test.jpeg"})
      end

      it "should return valid JSON when to_json is called on a collection containing uploader from a model" do
        @event[:image] = 'test.jpeg'
        @event.save!
        @event.reload

        expect(JSON.parse({:data => @event.image}.to_json)).to eq({"data"=>{"url"=>"/uploads/test.jpeg"}})
      end

      it "should return valid XML when to_xml is called when image is nil" do
        hash = Hash.from_xml(@event.to_xml)["event"]

        expect(@event[:image]).to be_nil
        expect(hash.keys).to include("image")
        expect(hash["image"].keys).to include("url")
        expect(hash["image"]["url"]).to be_nil
      end

      it "should return valid XML when to_xml is called when image is present" do
        @event[:image] = 'test.jpeg'
        @event.save!
        @event.reload

        expect(Hash.from_xml(@event.to_xml)["event"]["image"]).to eq({"url" => "/uploads/test.jpeg"})
      end

      it "should respect options[:only] when passed to as_json for the serializable hash" do
        @event[:image] = 'test.jpeg'
        @event.save!
        @event.reload

        expect(@event.as_json(:only => [:foo])).to eq({"foo" => nil})
      end

      it "should respect options[:except] when passed to as_json for the serializable hash" do
        @event[:image] = 'test.jpeg'
        @event.save!
        @event.reload

        expect(@event.as_json(:except => [:id, :image, :images, :textfiles, :foo])).to eq({"textfile" => nil})
      end
      it "should respect both options[:only] and options[:except] when passed to as_json for the serializable hash" do
        @event[:image] = 'test.jpeg'
        @event.save!
        @event.reload

        expect(@event.as_json(:only => [:foo], :except => [:id])).to eq({"foo" => nil})
      end

      it "should respect options[:only] when passed to to_xml for the serializable hash" do
        @event[:image] = 'test.jpeg'
        @event.save!
        @event.reload

        expect(Hash.from_xml(@event.to_xml(only: [:foo]))["event"]["image"]).to be_nil
      end

      it "should respect options[:except] when passed to to_xml for the serializable hash" do
        @event[:image] = 'test.jpeg'
        @event.save!
        @event.reload

        expect(Hash.from_xml(@event.to_xml(except: [:image]))["event"]["image"]).to be_nil
      end

      it "should respect both options[:only] and options[:except] when passed to to_xml for the serializable hash" do
        @event[:image] = 'test.jpeg'
        @event.save!
        @event.reload

        expect(Hash.from_xml(@event.to_xml(only: [:foo], except: [:id]))["event"]["image"]).to be_nil
      end

      it "resets cached value on record reload" do
        @event.image = CarrierWave::SanitizedFile.new(stub_file('new.jpeg', 'image/jpeg'))
        @event.save!

        expect(@event.reload.image).to be_present

        Event.find(@event.id).update_column(:image, nil)

        expect(@event.reload.image).to be_blank
      end

      context "with CarrierWave::MiniMagick" do
        before(:each) do
          @uploader.send(:include, CarrierWave::MiniMagick)
        end

        it "has width and height" do
          @event.image = stub_file('landscape.jpg')
          expect(@event.image.width).to eq 640
          expect(@event.image.height).to eq 480
        end
      end

      context "with CarrierWave::RMagick", :rmagick => true do
        before(:each) do
          @uploader.send(:include, CarrierWave::RMagick)
        end

        it "has width and height" do
          @event.image = stub_file('landscape.jpg')
          expect(@event.image.width).to eq 640
          expect(@event.image.height).to eq 480
        end
      end
    end

    describe '#image=' do

      it "should cache a file" do
        @event.image = stub_file('test.jpeg')
        expect(@event.image).to be_an_instance_of(@uploader)
      end

      it "should write nothing to the database, to prevent overridden filenames to fail because of unassigned attributes" do
        expect(@event[:image]).to be_nil
      end

      it "should copy a file into the cache directory" do
        @event.image = stub_file('test.jpeg')
        expect(@event.image.current_path).to match(%r(^#{public_path('uploads/tmp')}))
      end

      context "when empty string is assigned" do
        it "does nothing when" do
          @event.image = ''
          expect(@event.image).to be_blank
        end

        context "and the previous value was an empty string" do
          before do
            @event.image = ""
            @event.save
          end

          it "does not write to dirty changes" do
            @event.image = ''
            expect(@event.changes.keys).not_to include("image")
          end
        end

      end

      context "when nil is assigned" do
        it "does nothing" do
          @event.image = nil
          expect(@event.image).to be_blank
        end

        context "and the previous value was nil" do
          before do
            @event.image = nil
            @event.save
          end

          it "does not write to dirty changes" do
            @event.image = nil
            expect(@event.changes.keys).not_to include("image")
          end
        end
      end

      context 'when validating allowlist integrity' do
        before do
          @uploader.class_eval do
            def extension_allowlist
              %w(txt)
            end
          end
        end

        it "should use I18n for integrity error messages" do
          # Localize the error message to Dutch
          change_locale_and_store_translations(:nl, :errors => {
            :messages => {
              :extension_allowlist_error => "Het opladen van %{extension} bestanden is niet toe gestaan. Geaccepteerde types: %{allowed_types}"
            }
          }) do
            # Assigning image triggers check_allowlist! and thus should be inside change_locale_and_store_translations
            @event.image = stub_file('test.jpg')
            expect(@event).to_not be_valid
            @event.valid?
            expect(@event.errors[:image]).to eq(['Het opladen van "jpg" bestanden is niet toe gestaan. Geaccepteerde types: txt'])
          end
        end

        it "should set the error details" do
          @event.image = stub_file('test.jpg')
          expect(@event).to_not be_valid
          expect(@event.errors.details).to eq({image: [{error: :carrierwave_integrity_error}]})
        end
      end

      context 'when validating denylist integrity' do
        before do
          allow(CarrierWave.deprecator).to receive(:warn).with(/#extension_denylist/)
          @uploader.class_eval do
            def extension_denylist
              %w(jpg)
            end
          end
        end

        it "should use I18n for integrity error messages" do
          # Localize the error message to Dutch
          change_locale_and_store_translations(:nl, :errors => {
            :messages => {
              :extension_denylist_error => "You are not allowed to upload %{extension} files, prohibited types: %{prohibited_types}"
            }
          }) do
            # Assigning image triggers check_denylist! and thus should be inside change_locale_and_store_translations
            @event.image = stub_file('test.jpg')
            expect(@event).to_not be_valid
            @event.valid?
            expect(@event.errors[:image]).to eq(['You are not allowed to upload "jpg" files, prohibited types: jpg'])
          end
        end
      end

      context 'when validating processing' do
        before do
          @uploader.class_eval do
            process :monkey
            def monkey
              raise CarrierWave::ProcessingError
            end
          end
          @event.image = stub_file('test.jpg')
        end

        it "should make the record invalid when a processing error occurs" do
          expect(@event).to_not be_valid
        end

        it "should use I18n for processing errors without messages" do
          @event.valid?
          expect(@event.errors[:image]).to eq(['failed to be processed'])

          change_locale_and_store_translations(:pt, :activerecord => {
            :errors => {
              :messages => {
                :carrierwave_processing_error => 'falha ao processar imagem.'
              }
            }
          }) do
            expect(@event).to_not be_valid
            expect(@event.errors[:image]).to eq(['falha ao processar imagem.'])
          end
        end

        it "should set the error details" do
          @event.valid?
          expect(@event.errors.details).to eq({image: [{error: :carrierwave_processing_error}]})
        end
      end

      context 'when validating processing' do
        before do
          @uploader.class_eval do
            process :monkey
            def monkey
              raise CarrierWave::ProcessingError, "Ohh noez!"
            end
          end
          @event.image = stub_file('test.jpg')
        end

        it "should make the record invalid when a processing error occurs" do
          expect(@event).to_not be_valid
        end

        it "should use the error's messages for processing errors with messages" do
          @event.valid?
          expect(@event.errors[:image]).to eq(['Ohh noez!'])

          change_locale_and_store_translations(:pt, :activerecord => {
            :errors => {
              :messages => {
                :carrierwave_processing_error => 'falha ao processar imagem.'
              }
            }
          }) do
            expect(@event).to_not be_valid
            expect(@event.errors[:image]).to eq(['Ohh noez!'])
          end
        end
      end
    end

    describe '#save' do

      it "should do nothing when no file has been assigned" do
        expect(@event.save).to be_truthy
        expect(@event.image).to be_blank
      end

      it "should copy the file to the upload directory when a file has been assigned" do
        @event.image = stub_file('test.jpeg')
        expect(@event.save).to be_truthy
        expect(@event.image).to be_an_instance_of(@uploader)
        expect(@event.image.current_path).to eq public_path('uploads/test.jpeg')
      end

      it "should do nothing when a validation fails" do
        Event.validate { |r| r.errors.add :textfile, "FAIL!" }
        @event.image = stub_file('test.jpeg')

        expect(@event.save).to be_falsey
        expect(@event.image).to be_an_instance_of(@uploader)
        expect(@event.image.current_path).to match(/^#{public_path('uploads/tmp')}/)
      end

      it "should assign the filename to the database" do
        @event.image = stub_file('test.jpeg')
        expect(@event.save).to be_truthy
        @event.reload
        expect(@event[:image]).to eq('test.jpeg')
        expect(@event.image_identifier).to eq('test.jpeg')
      end

      it "should preserve the image when nothing is assigned" do
        @event.image = stub_file('test.jpeg')
        expect(@event.save).to be_truthy

        @event = Event.find(@event.id)
        @event.foo = "bar"

        expect(@event.save).to be_truthy
        expect(@event[:image]).to eq('test.jpeg')
        expect(@event.image_identifier).to eq('test.jpeg')
      end

      it "should remove the image if remove_image? returns true" do
        @event.image = stub_file('test.jpeg')
        @event.save!
        @event.remove_image = true
        @event.save!
        @event.reload
        expect(@event.image).to be_blank
        expect(@event[:image]).to eq(nil)
        expect(@event.image_identifier).to eq(nil)
      end

      it "should cancel removing image if remove_image is switched to false" do
        @event.image = stub_file('test.jpeg')
        @event.save!
        @event.remove_image = true
        @event.remove_image = false
        @event.save!
        @event.reload
        expect(@event[:image]).to eq('test.jpeg')
        expect(@event.image_identifier).to eq('test.jpeg')
      end

      it "should mark image as changed when saving a new image" do
        expect(@event.image_changed?).to be_falsey
        @event.image = stub_file("test.jpeg")
        expect(@event.image_changed?).to be_truthy
        @event.save
        @event.reload
        expect(@event.image_changed?).to be_falsey
        @event.image = stub_file("test.jpg")
        expect(@event.image_changed?).to be_truthy
        expect(@event.changed_for_autosave?).to be_truthy
      end

      it "should mark image as changed when saving a new image with same file name" do
        @event.image = stub_file("test.jpeg")
        @event.save
        @event.image = stub_tempfile("bork.txt", nil, "test.jpeg")
        expect(@event.image_changed?).to be_truthy
        @event.save
        expect(@event.reload.image.read).to match /^bork/
      end

      it "should not update image when save with select" do
        @event.image = stub_file('test.jpeg')
        @event.save!
        Event.select(:id).first.save!
        @event.reload
        expect(@event.image).to be_present
      end
    end

    describe "image?" do
      it "returns true when the file is cached" do
        @event.image = stub_file('test.jpg')

        expect(@event.image?).to be_truthy
      end

      it "returns false when the file is removed" do
        @event.remove_image!
        @event.save!

        expect(@event.image?).to be_falsey
      end

      it "returns true when the file is stored" do
        @event.image = stub_file('test.jpg')
        @event.save!

        expect(@event.image?).to be_truthy
      end

      it "returns true when a file is removed and stored again" do
        @event.image = stub_file('test.jpeg')
        @event.save!
        @event.remove_image!
        @event.save!
        @event.image = stub_file('test.jpeg')
        @event.save!

        expect(@event.image?).to be_truthy
      end
    end

    describe "remove_image!" do
      before do
        @event.image = stub_file('test.jpeg')
        @event.save!
      end

      it "should remove the file immediately" do
        file = @event.image.file
        @event.remove_image!

        expect(file).not_to exist
      end

      it "should clear the serialization column" do
        @event.remove_image!

        expect(@event.attributes['image']).to be_blank
      end

      it "resets remove_image? to false" do
        @event.remove_image = true

        expect {
          @event.remove_image!
        }.to change {
          @event.remove_image?
        }.from(true).to(false)
      end
    end

    describe "remove_image=" do
      before do
        @event.image = stub_file('test.jpeg')
        @event.save!
      end

      it "should mark the image as changed if changed" do
        expect(@event.image_changed?).to be_falsey
        expect(@event.remove_image).to be_nil
        @event.remove_image = "1"
        expect(@event.image_changed?).to be_truthy
      end

      it "resets remove_image? to false on save" do
        @event.remove_image = true

        expect {
          @event.save!
        }.to change {
          @event.remove_image?
        }.from(true).to(false)
      end
    end

    describe "#remote_image_url=" do
      before do
        stub_request(:get, "http://www.example.com/test.jpg").to_return(body: File.read(file_path("test.jpg")))
        stub_request(:get, "http://www.example.com/missing.jpg").to_return(status: 404)
      end

      # FIXME: ideally image_changed? and remote_image_url_changed? would return true
      it "should mark image as changed when setting remote_image_url" do
        expect(@event.image_changed?).to be_falsey
        @event.remote_image_url = 'http://www.example.com/test.jpg'
        expect(@event.image_changed?).to be_truthy
        @event.save!
        @event.reload
        expect(@event.image_changed?).to be_falsey
      end

      it "should clear validation errors from the previous attempt" do
        @event.remote_image_url = 'http://www.example.com/missing.jpg'
        expect(@event).to_not be_valid
        expect(@event.errors[:image]).to eq(['could not download file: 404 ""'])
        @event.remote_image_url = 'http://www.example.com/test.jpg'
        expect(@event).to be_valid
        expect(@event.errors).to be_empty
      end

      context 'when validating download' do
        before do
          @uploader.class_eval do
            def download!(file, headers = {})
              raise CarrierWave::DownloadError
            end
          end
          @event.remote_image_url = 'http://www.example.com/missing.jpg'
        end

        it "should make the record invalid when a download error occurs" do
          expect(@event).to_not be_valid
        end

        it "should use I18n for download errors without messages" do
          @event.valid?
          expect(@event.errors[:image]).to eq(['could not be downloaded'])

          change_locale_and_store_translations(:pt, :activerecord => {
            :errors => {
              :messages => {
                :carrierwave_download_error => 'não pode ser descarregado'
              }
            }
          }) do
            expect(@event).to_not be_valid
            expect(@event.errors[:image]).to eq(['não pode ser descarregado'])
          end
        end

        it "should set the error details" do
          @event.valid?
          expect(@event.errors.details).to eq({image: [{error: :carrierwave_download_error}]})
        end
      end

    end

    describe '#destroy' do

      it "should not raise an error with a custom filename" do
        @uploader.class_eval do
          def filename
            "page.jpeg"
          end
        end

        @event.image = stub_file('test.jpeg')
        expect(@event.save).to be_truthy
        expect {
          @event.destroy
        }.to_not raise_error
      end

      it "should do nothing when no file has been assigned" do
        expect(@event.save).to be_truthy
        @event.destroy
      end

      it "should remove the file from the filesystem" do
        @event.image = stub_file('test.jpeg')
        expect(@event.save).to be_truthy
        expect(@event.image).to be_an_instance_of(@uploader)
        expect(@event.image.current_path).to eq public_path('uploads/test.jpeg')
        @event.destroy
        expect(File.exist?(public_path('uploads/test.jpeg'))).to be_falsey
      end

    end

    describe '#changes' do
      it "should be generated" do
        allow(CarrierWave).to receive(:generate_cache_id).and_return('1369894322-345-1234-2255')
        @event.image = stub_file('test.jpeg')
        expect(@event.changes).to eq({'image' => [nil, '1369894322-345-1234-2255/test.jpeg']})
      end

      it "shouldn't be generated when the attribute value is unchanged" do
        @event.image = stub_file('test.jpeg')
        @event.save!
        @event.image = @event[:image]
        expect(@event).not_to be_changed
        @event.remote_image_url = ""
        expect(@event).not_to be_changed
      end
    end

    describe 'with overridden filename' do
      before do
        @uploader.class_eval do
          def filename
            model.name + File.extname(super)
          end
        end
        allow(@event).to receive(:name).and_return('jonas')
      end

      describe '#save' do

        it "should copy the file to the upload directory when a file has been assigned" do
          @event.image = stub_file('test.jpeg')
          expect(@event.save).to be_truthy
          expect(@event.image).to be_an_instance_of(@uploader)
          expect(@event.image.current_path).to eq(public_path('uploads/jonas.jpeg'))
        end

        it "should assign an overridden filename to the database" do
          @event.image = stub_file('test.jpeg')
          expect(@event.save).to be_truthy
          @event.reload
          expect(@event[:image]).to eq('jonas.jpeg')
        end

      end

      describe '#changes' do
        it "should be generated" do
          allow(CarrierWave).to receive(:generate_cache_id).and_return('1369894322-345-1234-2255')
          @event.image = stub_file('test.jpeg')
          expect(@event.changes).to eq({'image' => [nil, '1369894322-345-1234-2255/test.jpeg']})
        end

        it "shouldn't be generated after second save" do
          @event.image = stub_file('old.jpeg')
          @event.save!
          @event.image = stub_file('new.jpeg')
          @event.save!

          expect(@event.changes).to be_blank
          expect(@event).not_to be_changed
        end

        it "shouldn't be generated when remove_image is canceled" do
          @event.image = stub_file('test.jpeg')
          @event.save!
          @event.remove_image = true
          @event.remove_image = false

          expect(@event.changes).to be_blank
          expect(@event).not_to be_changed
        end
      end
    end

    describe 'with validates_presence_of' do

      before do
        Event.validates_presence_of :image
        allow(@event).to receive(:name).and_return('jonas')
      end

      it "should be valid if a file has been cached" do
        @event.image = stub_file('test.jpeg')
        expect(@event).to be_valid
      end

      it "should not be valid if a file has not been cached" do
        expect(@event).to_not be_valid
      end

    end

    describe 'with validates_size_of' do

      before do
        Event.validates_size_of :image, maximum: 40
        allow(@event).to receive(:name).and_return('jonas')
      end

      it "should be valid if a file has been cached that matches the size criteria" do
        @event.image = stub_file('test.jpeg')
        expect(@event).to be_valid
      end

      it "should not be valid if a file has been cached that does not match the size criteria" do
        @event.image = stub_file('bork.txt')
        expect(@event).to_not be_valid
      end

    end

    describe 'calling #update! on the instance' do
      before do
        @event.image = stub_file('test.jpeg')
        @event.save!
        @event.reload
      end

      it "allows clearing the stored image" do
        @event.update!(image: nil)
        expect(@event.image.file).to be_nil
        expect(File.exist?(public_path('uploads/test.jpeg'))).to be_falsy
        expect(@event[:image]).to be_nil
      end
    end
  end

  describe '#mount_uploader with mount_on' do
    describe '#avatar=' do
      it "should cache a file" do
        reset_class("Event")
        Event.mount_uploader(:avatar, @uploader, mount_on: :image)
        @event = Event.new
        @event.avatar = stub_file('test.jpeg')
        @event.save
        @event.reload

        expect(@event.avatar).to be_an_instance_of(@uploader)
        expect(@event.image).to eq('test.jpeg')
      end

    end
  end

  describe '#mount_uploader removing old files' do
    before do
      reset_class("Event")
    end

    after do
      FileUtils.rm_rf(public_path("uploads"))
    end

    describe 'normally' do
      before do
        Event.mount_uploader(:image, @uploader)
        @event = Event.new
        @event.image = stub_file('old.jpeg')

        expect(@event.save).to be_truthy
        expect(File.exist?(public_path('uploads/old.jpeg'))).to be_truthy
      end

      it "should remove old file if old file had a different path" do
        @event.image = stub_file('new.jpeg')
        expect(@event.save).to be_truthy
        expect(File.exist?(public_path('uploads/new.jpeg'))).to be_truthy
        expect(File.exist?(public_path('uploads/old.jpeg'))).to be_falsey
      end

      it "should not remove old file if old file had a different path but config is false" do
        @uploader.remove_previously_stored_files_after_update = false
        @event.image = stub_file('new.jpeg')
        expect(@event.save).to be_truthy
        expect(File.exist?(public_path('uploads/new.jpeg'))).to be_truthy
        expect(File.exist?(public_path('uploads/old.jpeg'))).to be_truthy
      end

      it "should give a different name to new file and remove the old file" do
        @event.image = stub_file('old.jpeg')
        expect(@event.save).to be_truthy
        expect(@event.image.current_path).to eq public_path('uploads/old(2).jpeg')
        expect(File.exist?(public_path('uploads/old.jpeg'))).to be_falsey
      end

      it "should persist the deduplicated filename" do
        @event.image = stub_file('old.jpeg')
        expect(@event.save).to be_truthy
        @event.reload
        expect(@event.image.current_path).to eq public_path('uploads/old(2).jpeg')
      end

      it "should not remove file if validations fail on save" do
        Event.validate { |r| r.errors.add :textfile, "FAIL!" }
        @event.image = stub_file('new.jpeg')

        expect(@event.save).to be_falsey
        expect(File.exist?(public_path('uploads/old.jpeg'))).to be_truthy
      end

      it "should only delete the file once when the file is removed" do
        @event.remove_image = true
        expect_any_instance_of(CarrierWave::SanitizedFile).to receive(:delete).exactly(1).times
        expect(@event.save).to be_truthy
      end
    end

    describe 'with an overridden filename' do
      before do
        Event.mount_uploader(:image, @uploader)
        @event = Event.new
        @uploader.class_eval do
          def filename
            model.foo + File.extname(super)
          end
        end

        @event.image = stub_file('old.jpeg')
        @event.foo = 'test'
        expect(@event.save).to be_truthy
        expect(File.exist?(public_path('uploads/test.jpeg'))).to be_truthy
        expect(@event.image.read).to eq('this is stuff')
      end

      it "should give a different name to new file and remove the old file" do
        @event.image = stub_file('test.jpeg')
        expect(@event.save).to be_truthy
        expect(@event.image.current_path).to eq public_path('uploads/test(2).jpeg')
        expect(File.exist?(public_path('uploads/test.jpeg'))).to be_falsey
      end

      it "should remove old file if old file had a different dynamic path" do
        @event.foo = "new"
        @event.image = stub_file('test.jpeg')
        expect(@event.save).to be_truthy
        expect(File.exist?(public_path('uploads/new.jpeg'))).to be_truthy
        expect(File.exist?(public_path('uploads/test.jpeg'))).to be_falsey
      end
    end

    describe 'with after_commit callbacks invoked by defined order' do
      before do
        ActiveRecord.run_after_transaction_callbacks_in_order_defined = true if ActiveRecord.respond_to?(:run_after_transaction_callbacks_in_order_defined=)
        Event.mount_uploader(:image, @uploader)
        @event = Event.new
        @event.image = stub_file('old.jpeg')

        expect(@event.save).to be_truthy
        expect(File.exist?(public_path('uploads/old.jpeg'))).to be_truthy
      end

      after do
        ActiveRecord.run_after_transaction_callbacks_in_order_defined = false if ActiveRecord.respond_to?(:run_after_transaction_callbacks_in_order_defined=)
      end

      it "should invoke the callbacks in correct order" do
        @event.image = stub_file('new.jpeg')
        expect(@event).to receive(:remove_previously_stored_image).ordered.and_call_original
        expect(@event).to receive(:reset_previous_changes_for_image).ordered.and_call_original
        expect(@event).to receive(:mark_remove_image_false).ordered.and_call_original
        @event.save
      end

      it "should remove old file on replace" do
        @event.image = stub_file('new.jpeg')
        expect(@event.save).to be_truthy
        expect(File.exist?(public_path('uploads/new.jpeg'))).to be_truthy
        expect(File.exist?(public_path('uploads/old.jpeg'))).to be_falsey
      end

      it "should remove the file when remove_image is set to true" do
        @event.remove_image = true
        expect(@event.save).to be_truthy
        expect(File.exist?(public_path('uploads/old.jpeg'))).to be_falsey
      end

      it "should remove old file on destroy" do
        expect(@event.destroy).to be_truthy
        expect(File.exist?(public_path('uploads/old.jpeg'))).to be_falsey
      end
    end
  end

  describe '#mount_uploader removing old files with versions' do
    before do
      @uploader.version :thumb
      reset_class("Event")
      Event.mount_uploader(:image, @uploader)
      @event = Event.new
      @event.image = stub_file('old.jpeg')

      expect(@event.save).to be_truthy
      expect(File.exist?(public_path('uploads/old.jpeg'))).to be_truthy
      expect(File.exist?(public_path('uploads/thumb_old.jpeg'))).to be_truthy
    end

    after do
      FileUtils.rm_rf(public_path("uploads"))
    end

    it "should remove old file if old file had a different path" do
      @event.image = stub_file('new.jpeg')
      expect(@event.save).to be_truthy
      expect(File.exist?(public_path('uploads/new.jpeg'))).to be_truthy
      expect(File.exist?(public_path('uploads/thumb_new.jpeg'))).to be_truthy
      expect(File.exist?(public_path('uploads/old.jpeg'))).to be_falsey
      expect(File.exist?(public_path('uploads/thumb_old.jpeg'))).to be_falsey
    end

    it "should give a different name to new file and remove the old file" do
      @event.image = stub_file('old.jpeg')
      expect(@event.save).to be_truthy
      expect(@event.image.current_path).to eq public_path('uploads/old(2).jpeg')
      expect(@event.image.thumb.current_path).to eq public_path('uploads/thumb_old(2).jpeg')
      expect(File.exist?(public_path('uploads/old.jpeg'))).to be_falsey
      expect(File.exist?(public_path('uploads/thumb_old.jpeg'))).to be_falsey
    end

    it 'should not remove old file if transaction is rollback' do
      Event.transaction do
        @event.image = stub_file('new.jpeg')
        @event.save
        expect(File.exist?(public_path('uploads/old.jpeg'))).to be_truthy
        raise ActiveRecord::Rollback
      end
      expect(File.exist?(public_path('uploads/old.jpeg'))).to be_truthy
    end

    it 'should remove new file if transaction is rollback' do
      Event.transaction do
        @event.image = stub_file('new.jpeg')
        @event.save
        expect(File.exist?(public_path('uploads/new.jpeg'))).to be_truthy
        raise ActiveRecord::Rollback
      end
      expect(File.exist?(public_path('uploads/new.jpeg'))).to be_falsey
    end

    it 'should not remove old file on rollback if file is not changed' do
      Event.transaction do
        @event.foo = 'test'
        @event.save
        expect(File.exist?(public_path('uploads/old.jpeg'))).to be_truthy
        raise ActiveRecord::Rollback
      end
      expect(File.exist?(public_path('uploads/old.jpeg'))).to be_truthy
    end

    it 'should give correct url during transaction' do
      Event.transaction do
        @event.image = stub_file('new.jpeg')
        @event.save
        expect(@event.image_url).to eq '/uploads/new.jpeg'
        raise ActiveRecord::Rollback
      end
    end

    it 'should raise error at save if storage cannot be done, preserving old' do
      allow(@event).to receive(:store_image!).and_raise(CarrierWave::UploadError)
      Event.transaction do
        @event.image = stub_file('new.jpeg')
        expect{ @event.save }.to raise_error(CarrierWave::UploadError)
        raise ActiveRecord::Rollback
      end
      expect(File.exist?(public_path('uploads/old.jpeg'))).to be_truthy
    end
  end

  describe "#mount_uploader into transaction" do
    before do
      @uploader.version :thumb
      reset_class("Event")
      Event.mount_uploader(:image, @uploader)
      @event = Event.new
    end

    after do
      FileUtils.rm_rf(public_path("uploads"))
    end

    it "should not store file during rollback" do
      Event.transaction do
        @event.image = stub_file('new.jpeg')
        @event.save

        raise ActiveRecord::Rollback
      end

      expect(File.exist?(public_path('uploads/new.jpeg'))).to be_falsey
    end

    it "should not change file during rollback" do
      @event.image = stub_file('old.jpeg')
      @event.save

      Event.transaction do
        @event.image = stub_file('new.jpeg')
        @event.save

        raise ActiveRecord::Rollback
      end

      expect(File.exist?(public_path('uploads/new.jpeg'))).to be_falsey
      expect(File.exist?(public_path('uploads/old.jpeg'))).to be_truthy
    end

    it 'should not remove a file if transaction is rollback' do
      @event.image = stub_file('new.jpeg')
      @event.save

      Event.transaction do
        @event.destroy
        raise ActiveRecord::Rollback
      end

      expect(File.exist?(public_path('uploads/new.jpeg'))).to be_truthy
    end

    it "should clear @added_uploaders on commit" do
      # Simulate the commit behavior, since we're using the transactional fixture
      @event.run_callbacks(:commit) do
        @event.image = stub_file('test.jpeg')
        @event.save!
      end
      expect(@event.send(:_mounter, :image).instance_variable_get(:@added_uploaders)).to be_blank
    end

    it "should remove all the previous images when saved multiple times" do
      # Simulate the commit behavior, since we're using the transactional fixture
      @event.run_callbacks(:commit) do
        @event.image = stub_file('test.jpeg')
        @event.save!
        @event.image = stub_file('bork.txt')
        @event.save!
        @event.image = stub_file('new.jpeg')
        @event.save!
      end
      expect(File.exist?(public_path('uploads/test.jpeg'))).to be false
      expect(File.exist?(public_path('uploads/bork.txt'))).to be false
    end
  end

  describe '#mount_uploader removing old files with multiple uploaders' do
    before do
      @uploader = Class.new(CarrierWave::Uploader::Base)
      @uploader1 = Class.new(CarrierWave::Uploader::Base)
      reset_class("Event")
      Event.mount_uploader(:image, @uploader)
      Event.mount_uploader(:textfile, @uploader1)
      @event = Event.new
      @event.image = stub_file('old.jpeg')
      @event.textfile = stub_file('old.txt')

      expect(@event.save).to be_truthy
      expect(File.exist?(public_path('uploads/old.jpeg'))).to be_truthy
      expect(File.exist?(public_path('uploads/old.txt'))).to be_truthy
    end

    after do
      FileUtils.rm_rf(public_path("uploads"))
    end

    it "should remove old file1 and file2 if old file1 and file2 had a different paths" do
      @event.image = stub_file('new.jpeg')
      @event.textfile = stub_file('new.txt')
      expect(@event.save).to be_truthy
      expect(File.exist?(public_path('uploads/new.jpeg'))).to be_truthy
      expect(File.exist?(public_path('uploads/old.jpeg'))).to be_falsey
      expect(File.exist?(public_path('uploads/new.txt'))).to be_truthy
      expect(File.exist?(public_path('uploads/old.txt'))).to be_falsey
    end

    it "should give a different name to file2 and remove the old files" do
      @event.image = stub_file('new.jpeg')
      @event.textfile = stub_file('old.txt')
      expect(@event.save).to be_truthy
      expect(File.exist?(public_path('uploads/new.jpeg'))).to be_truthy
      expect(File.exist?(public_path('uploads/old.jpeg'))).to be_falsey
      expect(File.exist?(public_path('uploads/old.txt'))).to be_falsey
      expect(@event.textfile.current_path).to eq public_path('uploads/old(2).txt')
    end

    it "should give different names to file1 and file2 and remove the old files" do
      @event.image = stub_file('old.jpeg')
      @event.textfile = stub_file('old.txt')
      expect(@event.save).to be_truthy
      expect(File.exist?(public_path('uploads/old.jpeg'))).to be_falsey
      expect(@event.image.current_path).to eq public_path('uploads/old(2).jpeg')
      expect(File.exist?(public_path('uploads/old.txt'))).to be_falsey
      expect(@event.textfile.current_path).to eq public_path('uploads/old(2).txt')
    end
  end

  describe '#mount_uploader removing old files with with mount_on' do
    before do
      reset_class("Event")
      Event.mount_uploader(:avatar, @uploader, mount_on: :image)
      @event = Event.new
      @event.avatar = stub_file('old.jpeg')

      expect(@event.save).to be_truthy
      expect(File.exist?(public_path('uploads/old.jpeg'))).to be_truthy
    end

    after do
      FileUtils.rm_rf(public_path("uploads"))
    end

    it "should remove old file if old file had a different path" do
      @event.avatar = stub_file('new.jpeg')
      expect(@event.save).to be_truthy
      expect(File.exist?(public_path('uploads/new.jpeg'))).to be_truthy
      expect(File.exist?(public_path('uploads/old.jpeg'))).to be_falsey
    end

    it "should give a different name to new file and remove the old file" do
      @event.avatar = stub_file('old.jpeg')
      expect(@event.save).to be_truthy
      expect(File.exist?(public_path('uploads/old.jpeg'))).to be_falsey
      expect(@event.avatar.current_path).to eq public_path('uploads/old(2).jpeg')
    end
  end

  describe '#mount_uploaders' do
    before do
      Event.mount_uploaders(:images, @uploader)
    end

    describe '#images' do

      it "should return blank uploader when nothing has been assigned" do
        expect(@event.images).to be_empty
      end

      it "should retrieve a file from the storage if a value is stored in the database" do
        @event[:images] = ['test.jpeg']
        @event.save!
        @event.reload
        expect(@event.images[0]).to be_an_instance_of(@uploader)
      end

      it "should set the path to the store dir" do
        @event[:images] = ['test.jpeg']
        @event.save!
        @event.reload
        expect(@event.images[0].current_path).to eq public_path('uploads/test.jpeg')
      end

      it "should return valid JSON when to_json is called when images is nil" do
        expect(@event[:images]).to be_nil
        hash = JSON.parse(@event.to_json)
        expect(hash.keys).to include("images")
        expect(hash["images"]).to be_empty
      end

      it "should return valid JSON when to_json is called when images is present" do
        @event[:images] = ['test.jpeg', 'old.jpeg']
        @event.save!
        @event.reload

        expect(JSON.parse(@event.to_json)["images"]).to eq([{"url" => "/uploads/test.jpeg"}, {"url" => "/uploads/old.jpeg"}])
      end

      it "should return valid JSON when to_json is called on a collection containing uploader from a model" do
        @event[:images] = ['test.jpeg']
        @event.save!
        @event.reload

        expect(JSON.parse({:data => @event.images}.to_json)).to eq({"data"=>[{"url"=>"/uploads/test.jpeg"}]})
      end

      it "should return valid XML when to_xml is called when images is nil" do
        hash = Hash.from_xml(@event.to_xml)["event"]

        expect(@event[:images]).to be_nil
        expect(hash.keys).to include("images")
        expect(hash["images"]).to be_empty
      end

      it "should return valid XML when to_xml is called when images is present" do
        @event[:images] = ['test.jpeg']
        @event.save!
        @event.reload

        expect(Hash.from_xml(@event.to_xml)["event"]["images"]).to eq([{"url" => "/uploads/test.jpeg"}])
      end

      it "should respect options[:only] when passed to as_json for the serializable hash" do
        @event[:images] = ['test.jpeg']
        @event.save!
        @event.reload

        expect(@event.as_json(:only => [:foo])).to eq({"foo" => nil})
      end

      it "should respect options[:except] when passed to as_json for the serializable hash" do
        @event[:images] = ['test.jpeg']
        @event.save!
        @event.reload

        expect(@event.as_json(:except => [:id, :image, :images, :textfile, :foo])).to eq({"textfiles" => nil})
      end
      it "should respect both options[:only] and options[:except] when passed to as_json for the serializable hash" do
        @event[:images] = ['test.jpeg']
        @event.save!
        @event.reload

        expect(@event.as_json(:only => [:foo], :except => [:id])).to eq({"foo" => nil})
      end

      it "should respect options[:only] when passed to to_xml for the serializable hash" do
        @event[:images] = ['test.jpeg']
        @event.save!
        @event.reload

        expect(Hash.from_xml(@event.to_xml(only: [:foo]))["event"]["images"]).to be_nil
      end

      it "should respect options[:except] when passed to to_xml for the serializable hash" do
        @event[:images] = ['test.jpeg']
        @event.save!
        @event.reload

        expect(Hash.from_xml(@event.to_xml(except: [:images]))["event"]["images"]).to be_nil
      end

      it "should respect both options[:only] and options[:except] when passed to to_xml for the serializable hash" do
        @event[:images] = ['test.jpeg']
        @event.save!
        @event.reload

        expect(Hash.from_xml(@event.to_xml(only: [:foo], except: [:id]))["event"]["images"]).to be_nil
      end
    end

    describe '#images=' do

      it "should cache a file" do
        @event.images = [stub_file('test.jpeg')]
        expect(@event.images[0]).to be_an_instance_of(@uploader)
      end

      it "should write nothing to the database, to prevent overridden filenames to fail because of unassigned attributes" do
        expect(@event[:images]).to be_nil
      end

      it "should copy a file into into the cache directory" do
        @event.images = [stub_file('test.jpeg')]
        expect(@event.images[0].current_path).to match(%r(^#{public_path('uploads/tmp')}))
      end

      it "should do nothing when nil is assigned" do
        @event.images = nil
        expect(@event.images).to be_empty
      end

      it "should do nothing when an empty string is assigned" do
        @event.images = ''
        expect(@event.images).to be_empty
      end

      context 'when validating allowlist integrity' do
        before do
          @uploader.class_eval do
            def extension_allowlist
              %w(txt)
            end
          end
        end

        it "should use I18n for integrity error messages" do
          # Localize the error message to Dutch
          change_locale_and_store_translations(:nl, :errors => {
            :messages => {
              :extension_allowlist_error => "Het opladen van %{extension} bestanden is niet toe gestaan. Geaccepteerde types: %{allowed_types}"
            }
          }) do
            # Assigning images triggers check_allowlist! and thus should be inside change_locale_and_store_translations
            @event.images = [stub_file('test.jpg')]
            expect(@event).to_not be_valid
            @event.valid?
            expect(@event.errors[:images]).to eq(['Het opladen van "jpg" bestanden is niet toe gestaan. Geaccepteerde types: txt'])
          end
        end
      end

      context 'when validating denylist integrity' do
        before do
          allow(CarrierWave.deprecator).to receive(:warn).with(/#extension_denylist/)
          @uploader.class_eval do
            def extension_denylist
              %w(jpg)
            end
          end
        end

        it "should use I18n for integrity error messages" do
          # Localize the error message to Dutch
          change_locale_and_store_translations(:nl, :errors => {
            :messages => {
              :extension_denylist_error => "You are not allowed to upload %{extension} files, prohibited types: %{prohibited_types}"
            }
          }) do
            # Assigning images triggers check_denylist! and thus should be inside change_locale_and_store_translations
            @event.images = [stub_file('test.jpg')]
            expect(@event).to_not be_valid
            @event.valid?
            expect(@event.errors[:images]).to eq(['You are not allowed to upload "jpg" files, prohibited types: jpg'])
          end
        end
      end

      context 'when validating processing' do
        before do
          @uploader.class_eval do
            process :monkey
            def monkey
              raise CarrierWave::ProcessingError
            end
          end
          @event.images = [stub_file('test.jpg')]
        end

        it "should make the record invalid when a processing error occurs" do
          expect(@event).to_not be_valid
        end

        it "should use I18n for processing errors without messages" do
          @event.valid?
          expect(@event.errors[:images]).to eq(['failed to be processed'])

          change_locale_and_store_translations(:pt, :activerecord => {
            :errors => {
              :messages => {
                :carrierwave_processing_error => 'falha ao processar imagesm.'
              }
            }
          }) do
            expect(@event).to_not be_valid
            expect(@event.errors[:images]).to eq(['falha ao processar imagesm.'])
          end
        end
      end

      context 'when validating processing' do
        before do
          @uploader.class_eval do
            process :monkey
            def monkey
              raise CarrierWave::ProcessingError, "Ohh noez!"
            end
          end
          @event.images = [stub_file('test.jpg')]
        end

        it "should make the record invalid when a processing error occurs" do
          expect(@event).to_not be_valid
        end

        it "should use the error's messages for processing errors with messages" do
          @event.valid?
          expect(@event.errors[:images]).to eq(['Ohh noez!'])

          change_locale_and_store_translations(:pt, :activerecord => {
            :errors => {
              :messages => {
                :carrierwave_processing_error => 'falha ao processar imagesm.'
              }
            }
          }) do
            expect(@event).to_not be_valid
            expect(@event.errors[:images]).to eq(['Ohh noez!'])
          end
        end
      end
    end

    describe '#save' do

      it "should do nothing when no file has been assigned" do
        expect(@event.save).to be_truthy
        expect(@event.images).to be_empty
      end

      it "should copy the file to the upload directory when a file has been assigned" do
        @event.images = [stub_file('test.jpeg')]
        expect(@event.save).to be_truthy
        expect(@event.images[0]).to be_an_instance_of(@uploader)
        expect(@event.images[0].current_path).to eq public_path('uploads/test.jpeg')
      end

      it "should do nothing when a validation fails" do
        Event.validate { |r| r.errors.add :textfile, "FAIL!" }
        @event.images = [stub_file('test.jpeg')]

        expect(@event.save).to be_falsey
        expect(@event.images[0]).to be_an_instance_of(@uploader)
        expect(@event.images[0].current_path).to match(/^#{public_path('uploads/tmp')}/)
      end

      it "should assign the filename to the database" do
        @event.images = [stub_file('test.jpeg')]
        expect(@event.save).to be_truthy
        @event.reload
        expect(@event[:images]).to eq(['test.jpeg'])
        expect(@event.images_identifiers[0]).to eq('test.jpeg')
      end

      it "should preserve the images when nothing is assigned" do
        @event.images = [stub_file('test.jpeg')]
        expect(@event.save).to be_truthy

        @event = Event.find(@event.id)
        @event.foo = "bar"

        expect(@event.save).to be_truthy
        expect(@event[:images]).to eq(['test.jpeg'])
        expect(@event.images_identifiers[0]).to eq('test.jpeg')
      end

      it "should remove the images if remove_images? returns true" do
        @event.images = [stub_file('test.jpeg')]
        @event.save!
        @event.remove_images = true
        @event.save!
        @event.reload
        expect(@event.images).to be_empty
        expect(@event[:images]).to eq(nil)
        expect(@event.images_identifiers[0]).to eq(nil)
      end

      it "should cancel removing images if remove_images is switched to false" do
        @event.images = [stub_file('test.jpeg')]
        @event.save!
        @event.remove_images = true
        @event.remove_images = false
        @event.save!
        @event.reload
        expect(@event[:images]).to eq(['test.jpeg'])
        expect(@event.images_identifiers[0]).to eq('test.jpeg')
      end

      it "should mark images as changed when saving new images" do
        expect(@event.images_changed?).to be_falsey
        @event.images = [stub_file("test.jpeg")]
        expect(@event.images_changed?).to be_truthy
        @event.save
        @event.reload
        expect(@event.images_changed?).to be_falsey
        @event.images = [stub_file("test.jpg")]
        expect(@event.images_changed?).to be_truthy
        expect(@event.changed_for_autosave?).to be_truthy
      end

      it "should mark images as changed when saving new images with same file name" do
        @event.images = [stub_file("test.jpeg")]
        @event.save
        @event.images = [stub_tempfile("bork.txt", nil, "test.jpeg")]
        expect(@event.images_changed?).to be_truthy
        @event.save
        expect(@event.reload.images[0].read).to match /^bork/
      end

      it "should not update image when save with select" do
        @event.images = [stub_file('test.jpeg')]
        @event.save!
        Event.select(:id).first.save!
        @event.reload
        expect(@event.images).to be_present
      end
    end

    describe "remove_images!" do
      before do
        @event.images = [stub_file('test.jpeg')]
        @event.save!
      end

      it "should clear the serialization column" do
        @event.remove_images!
        expect(@event.attributes['images']).to be_blank
      end

      it "should return to false" do
        @event.remove_images!
        expect(@event.remove_images).to be_falsy
        expect(@event.remove_images?).to eq(false)
      end

      it "should remove the file immediately" do
        file = @event.images.first.file
        @event.remove_images!

        expect(file).not_to exist
      end
    end

    describe "remove_images=" do
      before do
        @event.images = [stub_file('test.jpeg')]
        @event.save!
      end

      it "should mark the images as changed if changed" do
        expect(@event.images_changed?).to be_falsey
        expect(@event.remove_images).to be_nil
        @event.remove_images = "1"
        expect(@event.images_changed?).to be_truthy
      end

      it "should not mark the images as changed if falsey value is assigned" do
        @event.remove_images = "0"
        expect(@event.images_changed?).to be_falsey
        @event.remove_images = "false"
        expect(@event.images_changed?).to be_falsey
      end

      it "resets remove_images? to false on save" do
        @event.remove_images = true

        expect {
          @event.save!
        }.to change {
          @event.remove_images?
        }.from(true).to(false)
      end
    end

    describe "#remote_images_urls=" do
      before do
        stub_request(:get, "http://www.example.com/test.jpg").to_return(body: File.read(file_path("test.jpg")))
        stub_request(:get, "http://www.example.com/missing.jpg").to_return(status: 404)
      end

      # FIXME: ideally images_changed? and remote_images_urls_changed? would return true
      it "should mark images as changed when setting remote_images_urls" do
        expect(@event.images_changed?).to be_falsey
        @event.remote_images_urls = ['http://www.example.com/test.jpg']
        expect(@event.images_changed?).to be_truthy
        @event.save!
        @event.reload
        expect(@event.images_changed?).to be_falsey
      end

      it "should clear validation errors from the previous attempt" do
        @event.remote_images_urls = ['http://www.example.com/missing.jpg']
        expect(@event).to_not be_valid
        expect(@event.errors[:images]).to eq(['could not download file: 404 ""'])
        @event.remote_images_urls = ['http://www.example.com/test.jpg']
        expect(@event).to be_valid
        expect(@event.errors).to be_empty
      end

      context 'when validating download' do
        before do
          @uploader.class_eval do
            def download!(file, headers = {})
              raise CarrierWave::DownloadError
            end
          end
          @event.remote_images_urls = ['http://www.example.com/missing.jpg']
        end

        it "should make the record invalid when a download error occurs" do
          expect(@event).to_not be_valid
        end

        it "should use I18n for download errors without messages" do
          @event.valid?
          expect(@event.errors[:images]).to eq(['could not be downloaded'])

          change_locale_and_store_translations(:pt, :activerecord => {
            :errors => {
              :messages => {
                :carrierwave_download_error => 'não pode ser descarregado'
              }
            }
          }) do
            expect(@event).to_not be_valid
            expect(@event.errors[:images]).to eq(['não pode ser descarregado'])
          end
        end
      end

    end

    describe '#destroy' do

      it "should not raise an error with a custom filename" do
        @uploader.class_eval do
          def filename
            "page.jpeg"
          end
        end

        @event.images = [stub_file('test.jpeg')]
        expect(@event.save).to be_truthy
        expect {
          @event.destroy
        }.to_not raise_error
      end

      it "should do nothing when no file has been assigned" do
        expect(@event.save).to be_truthy
        @event.destroy
      end

      it "should remove the file from the filesystem" do
        @event.images = [stub_file('test.jpeg')]
        expect(@event.save).to be_truthy
        expect(@event.images[0]).to be_an_instance_of(@uploader)
        expect(@event.images[0].current_path).to eq public_path('uploads/test.jpeg')
        @event.destroy
        expect(File.exist?(public_path('uploads/test.jpeg'))).to be_falsey
      end

    end

    describe '#changes' do
      it "should be generated" do
        allow(CarrierWave).to receive(:generate_cache_id).and_return('1369894322-345-1234-2255')
        @event.images = [stub_file('test.jpeg')]
        expect(@event.changes).to eq({'images' => [nil, ['1369894322-345-1234-2255/test.jpeg']]})
      end

      it "shouldn't be generated when the attribute value is unchanged" do
        @event.images = [stub_file('test.jpeg')]
        @event.save!
        @event.images = @event[:images]
        expect(@event).not_to be_changed
        @event.remote_images_urls = [""]
        expect(@event).not_to be_changed
      end
    end

    describe 'with overridden filename' do

      describe '#save' do

        before do
          @uploader.class_eval do
            def filename
              model.name + File.extname(super)
            end
          end
          allow(@event).to receive(:name).and_return('jonas')
        end

        it "should copy the file to the upload directory when a file has been assigned" do
          @event.images = [stub_file('test.jpeg')]
          expect(@event.save).to be_truthy
          expect(@event.images[0]).to be_an_instance_of(@uploader)
          expect(@event.images[0].current_path).to eq(public_path('uploads/jonas.jpeg'))
        end

        it "should assign an overridden filename to the database" do
          @event.images = [stub_file('test.jpeg')]
          expect(@event.save).to be_truthy
          @event.reload
          expect(@event[:images]).to eq(['jonas.jpeg'])
        end

      end

    end

    describe 'with validates_presence_of' do

      before do
        Event.validates_presence_of :images
        allow(@event).to receive(:name).and_return('jonas')
      end

      it "should be valid if a file has been cached" do
        @event.images = [stub_file('test.jpeg')]
        expect(@event).to be_valid
      end

      it "should not be valid if a file has not been cached" do
        expect(@event).to_not be_valid
      end

    end

    describe 'with validates_size_of' do

      before do
        Event.validates_size_of :images, maximum: 2
        allow(@event).to receive(:name).and_return('jonas')
      end

      it "should be valid if at the number criteria are met" do
        @event.images = [stub_file('test.jpeg'), stub_file('old.jpeg')]
        expect(@event).to be_valid
      end

      it "should be invalid if size criteria are exceeded" do
        @event.images = [stub_file('test.jpeg'), stub_file('old.jpeg'), stub_file('new.jpeg')]
        expect(@event).to_not be_valid
      end

    end

    describe 'calling #update! on the instance' do
      before do
        @event.images = [stub_file('test.jpeg')]
        @event.save!
        @event.reload
      end

      it "allows clearing the stored images" do
        @event.update!(images: [])
        expect(@event.images).to be_empty
        expect(File.exist?(public_path('uploads/test.jpeg'))).to be_falsy
        expect(@event[:images]).to be nil
      end
    end
  end

  describe '#mount_uploaders with mount_on' do
    describe '#avatar=' do
      it "should cache a file" do
        reset_class("Event")
        Event.mount_uploaders(:avatar, @uploader, mount_on: :images)
        @event = Event.new
        @event.avatar = [stub_file('test.jpeg')]
        @event.save
        @event.reload

        expect(@event.avatar[0]).to be_an_instance_of(@uploader)
        expect(@event.images).to eq(['test.jpeg'])
      end

    end
  end

  describe '#mount_uploaders removing old files' do
    before do
      Event.mount_uploaders(:images, @uploader)
      @event.images = [stub_file('old.jpeg')]

      expect(@event.save).to be_truthy
      expect(File.exist?(public_path('uploads/old.jpeg'))).to be_truthy
    end

    after do
      FileUtils.rm_rf(public_path("uploads"))
    end

    describe 'normally' do
      it "should remove old file if old file had a different path" do
        @event.images = [stub_file('new.jpeg')]
        expect(@event.save).to be_truthy
        expect(File.exist?(public_path('uploads/new.jpeg'))).to be_truthy
        expect(File.exist?(public_path('uploads/old.jpeg'))).to be_falsey
      end

      it "should not remove old file if old file had a different path but config is false" do
        allow(@uploader).to receive(:remove_previously_stored_files_after_update).and_return(false)
        @event.images = [stub_file('new.jpeg')]
        expect(@event.save).to be_truthy
        expect(File.exist?(public_path('uploads/new.jpeg'))).to be_truthy
        expect(File.exist?(public_path('uploads/old.jpeg'))).to be_truthy
      end

      it "should give a different name to new file and remove the old file" do
        @event.images = [stub_file('old.jpeg')]
        expect(@event.save).to be_truthy
        expect(File.exist?(public_path('uploads/old.jpeg'))).to be_falsey
        expect(@event.images[0].current_path).to eq public_path('uploads/old(2).jpeg')
      end

      it "should persist the deduplicated filename" do
        @event.images = [stub_file('old.jpeg')]
        expect(@event.save).to be_truthy
        @event.reload
        expect(@event.images[0].current_path).to eq public_path('uploads/old(2).jpeg')
      end

      it "should not remove file if validations fail on save" do
        Event.validate { |r| r.errors.add :textfile, "FAIL!" }
        @event.images = [stub_file('new.jpeg')]

        expect(@event.save).to be_falsey
        expect(File.exist?(public_path('uploads/old.jpeg'))).to be_truthy
      end
    end

    describe 'with an overridden filename' do
      before do
        @uploader.class_eval do
          def filename
            model.foo + File.extname(super)
          end
        end

        @event.images = [stub_file('old.jpeg')]
        @event.foo = 'test'
        expect(@event.save).to be_truthy
        expect(File.exist?(public_path('uploads/test.jpeg'))).to be_truthy
        expect(@event.images[0].read).to eq('this is stuff')
      end

      it "should give a different name to new file and remove the old file" do
        @event.images = [stub_file('test.jpeg')]
        expect(@event.save).to be_truthy
        expect(@event.images[0].current_path).to eq public_path('uploads/test(2).jpeg')
        expect(File.exist?(public_path('uploads/test.jpeg'))).to be_falsey
      end

      it "should remove old file if old file had a different dynamic path" do
        @event.foo = "new"
        @event.images = [stub_file('test.jpeg')]
        expect(@event.save).to be_truthy
        expect(File.exist?(public_path('uploads/new.jpeg'))).to be_truthy
        expect(File.exist?(public_path('uploads/test.jpeg'))).to be_falsey
      end
    end
  end

  describe '#mount_uploaders removing old files with versions' do
    before do
      @uploader.version :thumb
      Event.mount_uploaders(:images, @uploader)
      @event.images = [stub_file('old.jpeg')]

      expect(@event.save).to be_truthy
      expect(File.exist?(public_path('uploads/old.jpeg'))).to be_truthy
      expect(File.exist?(public_path('uploads/thumb_old.jpeg'))).to be_truthy
    end

    after do
      FileUtils.rm_rf(public_path("uploads"))
    end

    it "should remove old file if old file had a different path" do
      @event.images = [stub_file('new.jpeg')]
      expect(@event.save).to be_truthy
      expect(File.exist?(public_path('uploads/new.jpeg'))).to be_truthy
      expect(File.exist?(public_path('uploads/thumb_new.jpeg'))).to be_truthy
      expect(File.exist?(public_path('uploads/old.jpeg'))).to be_falsey
      expect(File.exist?(public_path('uploads/thumb_old.jpeg'))).to be_falsey
    end

    it "should give a different name to new file and remove the old file" do
      @event.images = [stub_file('old.jpeg')]
      expect(@event.save).to be_truthy
      expect(@event.images[0].current_path).to eq public_path('uploads/old(2).jpeg')
      expect(@event.images[0].thumb.current_path).to eq public_path('uploads/thumb_old(2).jpeg')
      expect(File.exist?(public_path('uploads/old.jpeg'))).to be_falsey
      expect(File.exist?(public_path('uploads/thumb_old.jpeg'))).to be_falsey
    end
  end

  describe "#mount_uploaders into transaction" do
    before do
      @uploader.version :thumb
      reset_class("Event")
      Event.mount_uploaders(:images, @uploader)
      @event = Event.new
    end

    after do
      FileUtils.rm_rf(public_path("uploads"))
    end

    it "should clear @added_uploaders on commit" do
      # Simulate the commit behavior, since we're using the transactional fixture
      @event.run_callbacks(:commit) do
        @event.images = [stub_file('test.jpeg'), stub_file('bork.txt')]
        @event.save!
      end
      expect(@event.send(:_mounter, :images).instance_variable_get(:@added_uploaders)).to be_blank
    end

    it "should remove all the images when trying to remove them one by one" do
      # Simulate the commit behavior, since we're using the transactional fixture
      @event.run_callbacks(:commit) do
        @event.images = [stub_file('test.jpeg'), stub_file('bork.txt')]
        @event.save!
        @event.images = ['test.jpeg']
        @event.save!
        @event.images = []
        @event.save!
      end
      expect(@event.images).to be_empty
      expect(File.exist?(public_path('uploads/test.jpeg'))).to be false
      expect(File.exist?(public_path('uploads/bork.txt'))).to be false
    end
  end

  describe '#mount_uploaders removing old files with multiple uploaders' do
    before do
      @uploader = Class.new(CarrierWave::Uploader::Base)
      @uploader1 = Class.new(CarrierWave::Uploader::Base)
      reset_class("Event")
      Event.mount_uploaders(:images, @uploader)
      Event.mount_uploaders(:textfiles, @uploader1)
      @event = Event.new
      @event.images = [stub_file('old.jpeg')]
      @event.textfiles = [stub_file('old.txt')]

      expect(@event.save).to be_truthy
      expect(File.exist?(public_path('uploads/old.jpeg'))).to be_truthy
      expect(File.exist?(public_path('uploads/old.txt'))).to be_truthy
    end

    after do
      FileUtils.rm_rf(public_path("uploads"))
    end

    it "should remove old file1 and file2 if old file1 and file2 had a different paths" do
      @event.images = [stub_file('new.jpeg')]
      @event.textfiles = [stub_file('new.txt')]
      expect(@event.save).to be_truthy
      expect(File.exist?(public_path('uploads/new.jpeg'))).to be_truthy
      expect(File.exist?(public_path('uploads/old.jpeg'))).to be_falsey
      expect(File.exist?(public_path('uploads/new.txt'))).to be_truthy
      expect(File.exist?(public_path('uploads/old.txt'))).to be_falsey
    end

    it "should give a different name to file2 and remove the old files" do
      @event.images = [stub_file('new.jpeg')]
      @event.textfiles = [stub_file('old.txt')]
      expect(@event.save).to be_truthy
      expect(File.exist?(public_path('uploads/new.jpeg'))).to be_truthy
      expect(File.exist?(public_path('uploads/old.jpeg'))).to be_falsey
      expect(File.exist?(public_path('uploads/old.txt'))).to be_falsey
      expect(@event.textfiles[0].current_path).to eq public_path('uploads/old(2).txt')
    end

    it "should give different names to file1 and file2 and remove the old files" do
      @event.images = [stub_file('old.jpeg')]
      @event.textfiles = [stub_file('old.txt')]
      expect(@event.save).to be_truthy
      expect(File.exist?(public_path('uploads/old.jpeg'))).to be_falsey
      expect(@event.images[0].current_path).to eq public_path('uploads/old(2).jpeg')
      expect(File.exist?(public_path('uploads/old.txt'))).to be_falsey
      expect(@event.textfiles[0].current_path).to eq public_path('uploads/old(2).txt')
    end
  end

  describe '#mount_uploaders removing old files with mount_on' do
    before do
      Event.mount_uploaders(:avatar, @uploader, mount_on: :images)
      @event = Event.new
      @event.avatar = [stub_file('old.jpeg')]

      expect(@event.save).to be_truthy
      expect(File.exist?(public_path('uploads/old.jpeg'))).to be_truthy
    end

    after do
      FileUtils.rm_rf(public_path("uploads"))
    end

    it "should remove old file if old file had a different path" do
      @event.avatar = [stub_file('new.jpeg')]
      expect(@event.save).to be_truthy
      expect(File.exist?(public_path('uploads/new.jpeg'))).to be_truthy
      expect(File.exist?(public_path('uploads/old.jpeg'))).to be_falsey
    end

    it "should give a different name to new file and remove the old file" do
      @event.avatar = [stub_file('old.jpeg')]
      expect(@event.save).to be_truthy
      expect(File.exist?(public_path('uploads/old.jpeg'))).to be_falsey
      expect(@event.avatar[0].current_path).to eq public_path('uploads/old(2).jpeg')
    end

    it "should not raise ArgumentError when with_lock method is called" do
      expect { @event.with_lock {} }.to_not raise_error
    end
  end

  describe '#reload' do
    before do
      Event.mount_uploader(:image, @uploader)
    end

    context 'when #reload is overridden in the model' do
      before do
        Event.class_eval do
          def reload(*)
            super
          end
        end
        @event.save
        @event.image
      end

      it "clears @_mounters" do
        expect { @event.reload }.to change { @event.instance_variable_get(:@_mounters) }.to(nil)
      end
    end
  end

  describe "#dup" do
    before do
      Event.mount_uploader(:image, @uploader)
    end

    after do
      FileUtils.rm_rf(public_path("uploads"))
    end

    it "caches the existing file into the new model" do
      @event.image = stub_file('test.jpeg')
      @event.save
      new_event = @event.dup

      expect(new_event.image).to be_a(@uploader) & be_cached
      expect(new_event.image.filename).to eq("test.jpeg")
    end

    it "appropriately removes the model reference from the new models uploader" do
      @event.save
      new_event = @event.dup

      expect(new_event).not_to be @event
      expect(new_event.image.model).to be new_event
    end

    it "works when the mounters haven't been initialized" do
      expect(@event.instance_variable_defined?(:@_mounters)).to eq false
      expect(@event.dup).to be_a Event
    end

    it "clears previous attribute value to prevent unintended deduplication" do
      @event.image = stub_file('test.jpeg')
      @event.save
      new_event = @event.dup
      new_event.save

      expect(new_event.image.url).to eq '/uploads/test.jpeg'
    end

    it "does not modify the original object" do
      @event.image = stub_file('test.jpeg')
      @event.save
      expect { @event.dup }.not_to change { @event[:image] }
    end

    it "allows the original object to store a file" do
      @event.image = stub_file('test.jpeg')
      @event.dup

      expect(@event.save).to be_truthy
      expect(@event.image.path).to eq public_path('uploads/test.jpeg')
      expect(File.exist?(@event.image.path)).to be_truthy
    end

    context "with more than one mount" do
      before do
        @uploader1 = Class.new(CarrierWave::Uploader::Base)
        Event.mount_uploaders(:images, @uploader1)
      end

      it "caches the existing files into the new model" do
        @event.image = stub_file('test.jpeg')
        @event.images = [stub_file('test.jpg')]
        @event.save
        new_event = @event.dup

        expect(new_event.image).to be_cached & be_a(@uploader)
        expect(new_event.image.filename).to eq("test.jpeg")
        expect(new_event.images).to all(be_cached & be_a(@uploader1))
        expect(new_event.images.map(&:filename)).to eq ["test.jpg"]
      end

      it "appropriately removes the model references from the new models uploaders" do
        @event.save
        new_event = @event.dup

        expect(new_event).not_to be @event
        expect(new_event.image.model).to be new_event
      end

      it "works when the mounters haven't been initialized" do
        expect(@event.instance_variable_defined?(:@_mounters)).to eq false
        new_event = @event.dup

        expect(new_event).to be_a Event
        expect(new_event).not_to be @event
      end
    end

    context 'with store_dir using model attributes' do
      before do
        @uploader.class_eval do
          def store_dir
            "uploads/#{model.class.name.downcase}/#{mounted_as}/#{model.id}"
          end
        end
      end

      it "won't affect the duplicated object's saved path" do
        @event.image = stub_file('test.jpeg')
        expect(@event.save).to be_truthy
        expect(@event.image.current_path).to eq public_path("uploads/event/image/#{@event.id}/test.jpeg")

        new_event = @event.dup
        expect(new_event).not_to be @event
        expect(new_event.image.model).to be new_event
        expect(@event.image.current_path).to eq public_path("uploads/event/image/#{@event.id}/test.jpeg")

        expect(@event.save).to be_truthy
        expect(@event.image.current_path).to eq public_path("uploads/event/image/#{@event.id}/test.jpeg")
      end

      it "upload files to appropriate paths" do
        @event.image = stub_file('test.jpeg')
        new_event = @event.dup
        expect(new_event).not_to be @event

        expect(@event.save).to be_truthy
        expect(@event.image.path).to eq public_path("uploads/event/image/#{@event.id}/test.jpeg")
        expect(File.exist?(@event.image.path)).to be_truthy

        expect(new_event.save).to be_truthy
        expect(new_event.image.path).to eq public_path("uploads/event/image/#{new_event.id}/test.jpeg")
        expect(File.exist?(new_event.image.path)).to be_truthy
      end
    end

    context 'when #initialize_dup is overridden in the model' do
      before do
        Event.class_eval do
          def initialize_dup(*)
            super
          end
        end
        @event.image
      end

      it "recreates @_mounters" do
        expect(@event.dup.image.model).not_to eq @event
      end
    end

    context ':mount_on in options' do
      before { Event.mount_uploader(:image_v2, @uploader, mount_on: :image) }
      it do
        @event.image_v2 = stub_file('test.jpeg')
        @event.save
        new_event = @event.dup
        expect(new_event).not_to be @event
        expect(new_event.image_v2.model).to be new_event
      end
    end
  end

  describe 'when set as a nested attribute' do
    before(:all) do
      ActiveRecord::Base.connection.create_table('tickets', force: true) do |t|
        t.column :event_id, :integer
        t.column :image, :string
      end
    end
    after(:all) { drop_table("tickets") }

    before do
      Event.class_eval do
        has_many :tickets
        accepts_nested_attributes_for :tickets
      end
      reset_class("Ticket")
      Ticket.class_eval do
        mount_uploader(:image, @uploader)
        belongs_to :event
      end
      @ticket = Ticket.new
    end
    after do
      Ticket.delete_all
      FileUtils.rm_rf(public_path("uploads"))
    end

    describe '#cache_name=' do
      it "should allow the image to be stored" do
        cache_id = Ticket.new(image: stub_file('new.jpeg')).image_cache
        @event = Event.create(tickets: [Ticket.new])
        @event.update! tickets_attributes: {id: @event.tickets.first.id, image_cache: cache_id}
        expect(@event.tickets.first.image.to_s).to eq '/uploads/new.jpeg'
      end
    end
  end

  context "after recreating versions" do
    before do
      Event.mount_uploader(:image, @uploader)
      @event.update!(image: stub_file('test.jpeg'))
      @event.reload
      @event.image.recreate_versions!
    end

    it "should not break" do
      @event.save!
      expect(@event.image.file).to exist
    end
  end
end
