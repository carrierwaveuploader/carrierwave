# encoding: utf-8

require 'spec_helper'
require 'support/activerecord'

class TestMigration < ActiveRecord::Migration
  def self.up
    create_table :events, force: true do |t|
      t.column :image, :string
      t.column :images, :json
      t.column :textfile, :string
      t.column :textfiles, :json
      t.column :foo, :string
    end
  end

  def self.down
    drop_table :events
  end
end

class Event < ActiveRecord::Base; end # setup a basic AR class for testing
$arclass = 0

describe CarrierWave::ActiveRecord do
  before(:all) { TestMigration.up }
  after(:all) { TestMigration.down }

  before do
    sham_rack_app = ShamRack.at('www.example.com').stub
    sham_rack_app.register_resource('/test.jpg', File.read(file_path('test.jpg')), 'images/jpg')

    # Rails 4 defaults to no root in JSON, join the party
    ActiveRecord::Base.include_root_in_json = false
    # My god, what a horrible, horrible solution, but AR validations don't work
    # unless the class has a name. This is the best I could come up with :S
    $arclass += 1

    @class = Class.new(Event)
    # AR validations don't work unless the class has a name, and
    # anonymous classes can be named by assigning them to a constant
    Object.const_set("Event#{$arclass}", @class)
    @class.table_name = 'events'
    @uploader = Class.new(CarrierWave::Uploader::Base)
    @class.mount_uploader(:image, @uploader)
    @class.mount_uploaders(:images, @uploader)
    @event = @class.new
  end

  after do
    ShamRack.unmount_all
    Event.delete_all
  end

  describe '#mount_uploader' do
    describe '#image' do
      it 'should return blank uploader when nothing has been assigned' do
        expect(@event.image).to be_blank
      end

      it 'should return blank uploader when an empty string has been assigned' do
        @event[:image] = ''
        @event.save!
        @event.reload
        expect(@event.image).to be_blank
      end

      it 'should retrieve a file from the storage if a value is stored in the database' do
        @event[:image] = 'test.jpeg'
        @event.save!
        @event.reload
        expect(@event.image).to be_an_instance_of(@uploader)
      end

      it 'should set the path to the store dir' do
        @event[:image] = 'test.jpeg'
        @event.save!
        @event.reload
        expect(@event.image.current_path).to eq public_path('uploads/test.jpeg')
      end

      it 'should return valid JSON when to_json is called when image is nil' do
        expect(@event[:image]).to be_nil
        hash = JSON.parse(@event.to_json)
        expect(hash.keys).to include('image')
        expect(hash['image'].keys).to include('url')
        expect(hash['image']['url']).to be_nil
      end

      it 'should return valid JSON when to_json is called when image is present' do
        @event[:image] = 'test.jpeg'
        @event.save!
        @event.reload

        expect(JSON.parse(@event.to_json)['image']).to eq('url' => '/uploads/test.jpeg')
      end

      it 'should return valid JSON when to_json is called on a collection containing uploader from a model' do
        @event[:image] = 'test.jpeg'
        @event.save!
        @event.reload

        expect(JSON.parse({ data: @event.image }.to_json)).to eq('data' => { 'url' => '/uploads/test.jpeg' })
      end

      it 'should return valid XML when to_xml is called when image is nil' do
        expect(@event[:image]).to be_nil
        hash = Hash.from_xml(@event.to_xml)["event#{$arclass}"]
        expect(hash.keys).to include('image')
        expect(hash['image'].keys).to include('url')
        expect(hash['image']['url']).to be_nil
      end

      it 'should return valid XML when to_xml is called when image is present' do
        @event[:image] = 'test.jpeg'
        @event.save!
        @event.reload

        expect(Hash.from_xml(@event.to_xml)["event#{$arclass}"]['image']).to eq('url' => '/uploads/test.jpeg')
      end

      it 'should respect options[:only] when passed to as_json for the serializable hash' do
        @event[:image] = 'test.jpeg'
        @event.save!
        @event.reload

        expect(@event.as_json(only: [:foo])).to eq('foo' => nil)
      end

      it 'should respect options[:except] when passed to as_json for the serializable hash' do
        @event[:image] = 'test.jpeg'
        @event.save!
        @event.reload

        expect(@event.as_json(except: [:id, :image, :images, :textfiles, :foo])).to eq('textfile' => nil)
      end
      it 'should respect both options[:only] and options[:except] when passed to as_json for the serializable hash' do
        @event[:image] = 'test.jpeg'
        @event.save!
        @event.reload

        expect(@event.as_json(only: [:foo], except: [:id])).to eq('foo' => nil)
      end

      it 'should respect options[:only] when passed to to_xml for the serializable hash' do
        @event[:image] = 'test.jpeg'
        @event.save!
        @event.reload

        expect(Hash.from_xml(@event.to_xml(only: [:foo]))["event#{$arclass}"]['image']).to be_nil
      end

      it 'should respect options[:except] when passed to to_xml for the serializable hash' do
        @event[:image] = 'test.jpeg'
        @event.save!
        @event.reload

        expect(Hash.from_xml(@event.to_xml(except: [:image]))["event#{$arclass}"]['image']).to be_nil
      end

      it 'should respect both options[:only] and options[:except] when passed to to_xml for the serializable hash' do
        @event[:image] = 'test.jpeg'
        @event.save!
        @event.reload

        expect(Hash.from_xml(@event.to_xml(only: [:foo], except: [:id]))["event#{$arclass}"]['image']).to be_nil
      end

      it 'resets cached value on record reload' do
        @event.image = CarrierWave::SanitizedFile.new(stub_file('new.jpeg', 'image/jpeg'))
        @event.save!

        expect(@event.reload.image).to be_present
        @class.find(@event.id).update_column(:image, nil)

        expect(@event.reload.image).to be_blank
      end
    end

    describe '#image=' do
      it 'should cache a file' do
        @event.image = stub_file('test.jpeg')
        expect(@event.image).to be_an_instance_of(@uploader)
      end

      it 'should write nothing to the database, to prevent overriden filenames to fail because of unassigned attributes' do
        expect(@event[:image]).to be_nil
      end

      it 'should copy a file into into the cache directory' do
        @event.image = stub_file('test.jpeg')
        expect(@event.image.current_path).to match(%r{^#{public_path('uploads/tmp')}})
      end

      it 'should do nothing when nil is assigned' do
        @event.image = nil
        expect(@event.image).to be_blank
      end

      it 'should do nothing when an empty string is assigned' do
        @event.image = ''
        expect(@event.image).to be_blank
      end

      context 'when validating white list integrity' do
        before do
          @uploader.class_eval do
            def extension_white_list
              %w(txt)
            end
          end
        end

        it 'should use I18n for integrity error messages' do
          # Localize the error message to Dutch
          change_locale_and_store_translations(:nl, errors: {
                                                 messages: {
                                                   extension_white_list_error: 'Het opladen van %{extension} bestanden is niet toe gestaan. Geaccepteerde types: %{allowed_types}'
                                                 }
                                               }) do
            # Assigning image triggers check_whitelist! and thus should be inside change_locale_and_store_translations
            @event.image = stub_file('test.jpg')
            expect(@event).to_not be_valid
            @event.valid?
            expect(@event.errors[:image]).to eq (['Het opladen van "jpg" bestanden is niet toe gestaan. Geaccepteerde types: txt'])
          end
        end
      end

      context 'when validating black list integrity' do
        before do
          @uploader.class_eval do
            def extension_black_list
              %w(jpg)
            end
          end
        end

        it 'should use I18n for integrity error messages' do
          # Localize the error message to Dutch
          change_locale_and_store_translations(:nl, errors: {
                                                 messages: {
                                                   extension_black_list_error: 'You are not allowed to upload %{extension} files, prohibited types: %{prohibited_types}'
                                                 }
                                               }) do
            # Assigning image triggers check_blacklist! and thus should be inside change_locale_and_store_translations
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
              fail CarrierWave::ProcessingError
            end
          end
          @event.image = stub_file('test.jpg')
        end

        it 'should make the record invalid when a processing error occurs' do
          expect(@event).to_not be_valid
        end

        it 'should use I18n for processing errors without messages' do
          @event.valid?
          expect(@event.errors[:image]).to eq(['failed to be processed'])

          change_locale_and_store_translations(:pt, activerecord: {
                                                 errors: {
                                                   messages: {
                                                     carrierwave_processing_error: 'falha ao processar imagem.'
                                                   }
                                                 }
                                               }) do
            expect(@event).to_not be_valid
            expect(@event.errors[:image]).to eq(['falha ao processar imagem.'])
          end
        end
      end

      context 'when validating processing' do
        before do
          @uploader.class_eval do
            process :monkey
            def monkey
              fail CarrierWave::ProcessingError, 'Ohh noez!'
            end
          end
          @event.image = stub_file('test.jpg')
        end

        it 'should make the record invalid when a processing error occurs' do
          expect(@event).to_not be_valid
        end

        it "should use the error's messages for processing errors with messages" do
          @event.valid?
          expect(@event.errors[:image]).to eq(['Ohh noez!'])

          change_locale_and_store_translations(:pt, activerecord: {
                                                 errors: {
                                                   messages: {
                                                     carrierwave_processing_error: 'falha ao processar imagem.'
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
      it 'should do nothing when no file has been assigned' do
        expect(@event.save).to be_true
        expect(@event.image).to be_blank
      end

      it 'should copy the file to the upload directory when a file has been assigned' do
        @event.image = stub_file('test.jpeg')
        expect(@event.save).to be_true
        expect(@event.image).to be_an_instance_of(@uploader)
        expect(@event.image.current_path).to eq public_path('uploads/test.jpeg')
      end

      it 'should do nothing when a validation fails' do
        @class.validate { |r| r.errors.add :textfile, 'FAIL!' }
        @event.image = stub_file('test.jpeg')
        expect(@event.save).to be_false
        expect(@event.image).to be_an_instance_of(@uploader)
        expect(@event.image.current_path).to match(/^#{public_path('uploads/tmp')}/)
      end

      it 'should assign the filename to the database' do
        @event.image = stub_file('test.jpeg')
        expect(@event.save).to be_true
        @event.reload
        expect(@event[:image]).to eq('test.jpeg')
        expect(@event.image_identifier).to eq('test.jpeg')
      end

      it 'should preserve the image when nothing is assigned' do
        @event.image = stub_file('test.jpeg')
        expect(@event.save).to be_true
        @event = @class.find(@event.id)
        @event.foo = 'bar'
        expect(@event.save).to be_true
        expect(@event[:image]).to eq('test.jpeg')
        expect(@event.image_identifier).to eq('test.jpeg')
      end

      it 'should remove the image if remove_image? returns true' do
        @event.image = stub_file('test.jpeg')
        @event.save!
        @event.remove_image = true
        @event.save!
        @event.reload
        expect(@event.image).to be_blank
        expect(@event[:image]).to eq(nil)
        expect(@event.image_identifier).to eq(nil)
      end

      it 'should mark image as changed when saving a new image' do
        expect(@event.image_changed?).to be_false
        @event.image = stub_file('test.jpeg')
        expect(@event.image_changed?).to be_true
        @event.save
        @event.reload
        expect(@event.image_changed?).to be_false
        @event.image = stub_file('test.jpg')
        expect(@event.image_changed?).to be_true
        expect(@event.changed_for_autosave?).to be_true
      end
    end

    describe 'remove_image!' do
      before do
        @event.image = stub_file('test.jpeg')
        @event.save!
        @event.remove_image!
      end

      it 'should clear the serialization column' do
        expect(@event.attributes['image']).to be_blank
      end

      it 'should return to false after being saved' do
        @event.save!
        @event.remove_image.should == false
        @event.remove_image?.should == false
      end
    end

    describe 'remove_image=' do
      it 'should mark the image as changed if changed' do
        expect(@event.image_changed?).to be_false
        @event.remove_image.should be_nil
        @event.remove_image = '1'
        expect(@event.image_changed?).to be_true
      end
    end

    describe '#remote_image_url=' do
      # FIXME ideally image_changed? and remote_image_url_changed? would return true
      it 'should mark image as changed when setting remote_image_url' do
        expect(@event.image_changed?).to be_false
        @event.remote_image_url = 'http://www.example.com/test.jpg'
        expect(@event.image_changed?).to be_true
        @event.save!
        @event.reload
        expect(@event.image_changed?).to be_false
      end

      context 'when validating download' do
        before do
          @uploader.class_eval do
            def download!(_file)
              fail CarrierWave::DownloadError
            end
          end
          @event.remote_image_url = 'http://www.example.com/missing.jpg'
        end

        it 'should make the record invalid when a download error occurs' do
          expect(@event).to_not be_valid
        end

        it 'should use I18n for download errors without messages' do
          @event.valid?
          expect(@event.errors[:image]).to eq(['could not be downloaded'])

          change_locale_and_store_translations(:pt, activerecord: {
                                                 errors: {
                                                   messages: {
                                                     carrierwave_download_error: 'não pode ser descarregado'
                                                   }
                                                 }
                                               }) do
            expect(@event).to_not be_valid
            expect(@event.errors[:image]).to eq(['não pode ser descarregado'])
          end
        end
      end
    end

    describe '#destroy' do
      it 'should not raise an error with a custom filename' do
        @uploader.class_eval do
          def filename
            'page.jpeg'
          end
        end

        @event.image = stub_file('test.jpeg')
        expect(@event.save).to be_true
        expect do
          @event.destroy
        end.to_not raise_error
      end

      it 'should do nothing when no file has been assigned' do
        expect(@event.save).to be_true
        @event.destroy
      end

      it 'should remove the file from the filesystem' do
        @event.image = stub_file('test.jpeg')
        expect(@event.save).to be_true
        expect(@event.image).to be_an_instance_of(@uploader)
        expect(@event.image.current_path).to eq public_path('uploads/test.jpeg')
        @event.destroy
        expect(File.exist?(public_path('uploads/test.jpeg'))).to be_false
      end
    end

    describe 'with overriddent filename' do
      describe '#save' do
        before do
          @uploader.class_eval do
            def filename
              model.name + File.extname(super)
            end
          end
          @event.stub(:name).and_return('jonas')
        end

        it 'should copy the file to the upload directory when a file has been assigned' do
          @event.image = stub_file('test.jpeg')
          expect(@event.save).to be_true
          expect(@event.image).to be_an_instance_of(@uploader)
          expect(@event.image.current_path).to eq(public_path('uploads/jonas.jpeg'))
        end

        it 'should assign an overridden filename to the database' do
          @event.image = stub_file('test.jpeg')
          expect(@event.save).to be_true
          @event.reload
          expect(@event[:image]).to eq('jonas.jpeg')
        end
      end
    end

    describe 'with validates_presence_of' do
      before do
        @class.validates_presence_of :image
        @event.stub(:name).and_return('jonas')
      end

      it 'should be valid if a file has been cached' do
        @event.image = stub_file('test.jpeg')
        expect(@event).to be_valid
      end

      it 'should not be valid if a file has not been cached' do
        expect(@event).to_not be_valid
      end
    end

    describe 'with validates_size_of' do
      before do
        @class.validates_size_of :image, maximum: 40
        @event.stub(:name).and_return('jonas')
      end

      it 'should be valid if a file has been cached that matches the size criteria' do
        @event.image = stub_file('test.jpeg')
        expect(@event).to be_valid
      end

      it 'should not be valid if a file has been cached that does not match the size criteria' do
        @event.image = stub_file('bork.txt')
        expect(@event).to_not be_valid
      end
    end
  end

  describe '#mount_uploader with mount_on' do
    before do
      @class = Class.new(Event)
      @class.table_name = 'events'
      @uploader = Class.new(CarrierWave::Uploader::Base)
      @class.mount_uploader(:avatar, @uploader, mount_on: :image)
      @event = @class.new
    end

    describe '#avatar=' do
      it 'should cache a file' do
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
      @class = Class.new(Event)
      @class.table_name = 'events'
      @uploader = Class.new(CarrierWave::Uploader::Base)
      @class.mount_uploader(:image, @uploader)
      @event = @class.new
      @event.image = stub_file('old.jpeg')
      expect(@event.save).to be_true
      expect(File.exist?(public_path('uploads/old.jpeg'))).to be_true
    end

    after do
      FileUtils.rm_rf(file_path('uploads'))
    end

    describe 'normally' do
      it 'should remove old file if old file had a different path' do
        @event.image = stub_file('new.jpeg')
        expect(@event.save).to be_true
        expect(File.exist?(public_path('uploads/new.jpeg'))).to be_true
        expect(File.exist?(public_path('uploads/old.jpeg'))).to be_false
      end

      it 'should not remove old file if old file had a different path but config is false' do
        @uploader.remove_previously_stored_files_after_update = false
        @event.image = stub_file('new.jpeg')
        expect(@event.save).to be_true
        expect(File.exist?(public_path('uploads/new.jpeg'))).to be_true
        expect(File.exist?(public_path('uploads/old.jpeg'))).to be_true
      end

      it 'should not remove file if old file had the same path' do
        @event.image = stub_file('old.jpeg')
        expect(@event.save).to be_true
        expect(File.exist?(public_path('uploads/old.jpeg'))).to be_true
      end

      it 'should not remove file if validations fail on save' do
        @class.validate { |r| r.errors.add :textfile, 'FAIL!' }
        @event.image = stub_file('new.jpeg')
        expect(@event.save).to be_false
        expect(File.exist?(public_path('uploads/old.jpeg'))).to be_true
      end

      pending do
        it 'should only delete the file once when the file is removed' do
          @event.remove_image = true
          expect_any_instance_of(CarrierWave::SanitizedFile).to receive(:delete).exactly(1).times
          expect(@event.save).to be_true
        end
      end
    end

    describe 'with an overriden filename' do
      before do
        @uploader.class_eval do
          def filename
            model.foo + File.extname(super)
          end
        end

        @event.image = stub_file('old.jpeg')
        @event.foo = 'test'
        expect(@event.save).to be_true
        expect(File.exist?(public_path('uploads/test.jpeg'))).to be_true
        expect(@event.image.read).to eq('this is stuff')
      end

      it 'should not remove file if old file had the same dynamic path' do
        @event.image = stub_file('test.jpeg')
        expect(@event.save).to be_true
        expect(File.exist?(public_path('uploads/test.jpeg'))).to be_true
      end

      it 'should remove old file if old file had a different dynamic path' do
        @event.foo = 'new'
        @event.image = stub_file('test.jpeg')
        expect(@event.save).to be_true
        expect(File.exist?(public_path('uploads/new.jpeg'))).to be_true
        expect(File.exist?(public_path('uploads/test.jpeg'))).to be_false
      end
    end
  end

  describe '#mount_uploader removing old files with versions' do
    before do
      @class = Class.new(Event)
      @class.table_name = 'events'
      @uploader = Class.new(CarrierWave::Uploader::Base)
      @uploader.version :thumb
      @class.mount_uploader(:image, @uploader)
      @event = @class.new
      @event.image = stub_file('old.jpeg')
      expect(@event.save).to be_true
      expect(File.exist?(public_path('uploads/old.jpeg'))).to be_true
      expect(File.exist?(public_path('uploads/thumb_old.jpeg'))).to be_true
    end

    after do
      FileUtils.rm_rf(file_path('uploads'))
    end

    it 'should remove old file if old file had a different path' do
      @event.image = stub_file('new.jpeg')
      expect(@event.save).to be_true
      expect(File.exist?(public_path('uploads/new.jpeg'))).to be_true
      expect(File.exist?(public_path('uploads/thumb_new.jpeg'))).to be_true
      expect(File.exist?(public_path('uploads/old.jpeg'))).to be_false
      expect(File.exist?(public_path('uploads/thumb_old.jpeg'))).to be_false
    end

    it 'should not remove file if old file had the same path' do
      @event.image = stub_file('old.jpeg')
      expect(@event.save).to be_true
      expect(File.exist?(public_path('uploads/old.jpeg'))).to be_true
      expect(File.exist?(public_path('uploads/thumb_old.jpeg'))).to be_true
    end

    it 'should not remove old file if transaction is rollback' do
      Event.transaction do
        @event.image = stub_file('new.jpeg')
        @event.save
        expect(File.exist?(public_path('uploads/new.jpeg'))).to be_true
        expect(File.exist?(public_path('uploads/old.jpeg'))).to be_true
        fail ActiveRecord::Rollback
      end
      expect(File.exist?(public_path('uploads/old.jpeg'))).to be_true
    end
  end

  describe '#mount_uploader removing old files with multiple uploaders' do
    before do
      @class = Class.new(Event)
      @class.table_name = 'events'
      @uploader = Class.new(CarrierWave::Uploader::Base)
      @class.mount_uploader(:image, @uploader)
      @uploader1 = Class.new(CarrierWave::Uploader::Base)
      @class.mount_uploader(:textfile, @uploader1)
      @event = @class.new
      @event.image = stub_file('old.jpeg')
      @event.textfile = stub_file('old.txt')
      expect(@event.save).to be_true
      expect(File.exist?(public_path('uploads/old.jpeg'))).to be_true
      expect(File.exist?(public_path('uploads/old.txt'))).to be_true
    end

    after do
      FileUtils.rm_rf(file_path('uploads'))
    end

    it 'should remove old file1 and file2 if old file1 and file2 had a different paths' do
      @event.image = stub_file('new.jpeg')
      @event.textfile = stub_file('new.txt')
      expect(@event.save).to be_true
      expect(File.exist?(public_path('uploads/new.jpeg'))).to be_true
      expect(File.exist?(public_path('uploads/old.jpeg'))).to be_false
      expect(File.exist?(public_path('uploads/new.txt'))).to be_true
      expect(File.exist?(public_path('uploads/old.txt'))).to be_false
    end

    it 'should remove old file1 but not file2 if old file1 had a different path but old file2 has the same path' do
      @event.image = stub_file('new.jpeg')
      @event.textfile = stub_file('old.txt')
      expect(@event.save).to be_true
      expect(File.exist?(public_path('uploads/new.jpeg'))).to be_true
      expect(File.exist?(public_path('uploads/old.jpeg'))).to be_false
      expect(File.exist?(public_path('uploads/old.txt'))).to be_true
    end

    it 'should not remove file1 or file2 if file1 and file2 have the same paths' do
      @event.image = stub_file('old.jpeg')
      @event.textfile = stub_file('old.txt')
      expect(@event.save).to be_true
      expect(File.exist?(public_path('uploads/old.jpeg'))).to be_true
      expect(File.exist?(public_path('uploads/old.txt'))).to be_true
    end
  end

  describe '#mount_uploader removing old files with with mount_on' do
    before do
      @class = Class.new(Event)
      @class.table_name = 'events'
      @uploader = Class.new(CarrierWave::Uploader::Base)
      @class.mount_uploader(:avatar, @uploader, mount_on: :image)
      @event = @class.new
      @event.avatar = stub_file('old.jpeg')
      expect(@event.save).to be_true
      expect(File.exist?(public_path('uploads/old.jpeg'))).to be_true
    end

    after do
      FileUtils.rm_rf(file_path('uploads'))
    end

    it 'should remove old file if old file had a different path' do
      @event.avatar = stub_file('new.jpeg')
      expect(@event.save).to be_true
      expect(File.exist?(public_path('uploads/new.jpeg'))).to be_true
      expect(File.exist?(public_path('uploads/old.jpeg'))).to be_false
    end

    it 'should not remove file if old file had the same path' do
      @event.avatar = stub_file('old.jpeg')
      expect(@event.save).to be_true
      expect(File.exist?(public_path('uploads/old.jpeg'))).to be_true
    end
  end

  describe '#mount_uploaders' do
    describe '#images' do
      it 'should return blank uploader when nothing has been assigned' do
        expect(@event.images).to be_empty
      end

      it 'should retrieve a file from the storage if a value is stored in the database' do
        @event[:images] = ['test.jpeg'].to_json
        @event.save!
        @event.reload
        expect(@event.images[0]).to be_an_instance_of(@uploader)
      end

      it 'should set the path to the store dir' do
        @event[:images] = ['test.jpeg'].to_json
        @event.save!
        @event.reload
        expect(@event.images[0].current_path).to eq public_path('uploads/test.jpeg')
      end

      it 'should return valid JSON when to_json is called when images is nil' do
        expect(@event[:images]).to be_nil
        hash = JSON.parse(@event.to_json)
        expect(hash.keys).to include('images')
        expect(hash['images']).to be_empty
      end

      it 'should return valid JSON when to_json is called when images is present' do
        @event[:images] = ['test.jpeg', 'old.jpeg'].to_json
        @event.save!
        @event.reload

        expect(JSON.parse(@event.to_json)['images']).to eq([{ 'url' => '/uploads/test.jpeg' }, { 'url' => '/uploads/old.jpeg' }])
      end

      it 'should return valid JSON when to_json is called on a collection containing uploader from a model' do
        @event[:images] = ['test.jpeg'].to_json
        @event.save!
        @event.reload

        expect(JSON.parse({ data: @event.images }.to_json)).to eq('data' => [{ 'url' => '/uploads/test.jpeg' }])
      end

      it 'should return valid XML when to_xml is called when images is nil' do
        expect(@event[:images]).to be_nil
        hash = Hash.from_xml(@event.to_xml)["event#{$arclass}"]
        expect(hash.keys).to include('images')
        expect(hash['images']).to be_empty
      end

      it 'should return valid XML when to_xml is called when images is present' do
        @event[:images] = ['test.jpeg'].to_json
        @event.save!
        @event.reload

        expect(Hash.from_xml(@event.to_xml)["event#{$arclass}"]['images']).to eq([{ 'url' => '/uploads/test.jpeg' }])
      end

      it 'should respect options[:only] when passed to as_json for the serializable hash' do
        @event[:images] = ['test.jpeg'].to_json
        @event.save!
        @event.reload

        expect(@event.as_json(only: [:foo])).to eq('foo' => nil)
      end

      it 'should respect options[:except] when passed to as_json for the serializable hash' do
        @event[:images] = ['test.jpeg'].to_json
        @event.save!
        @event.reload

        expect(@event.as_json(except: [:id, :image, :images, :textfile, :foo])).to eq('textfiles' => nil)
      end
      it 'should respect both options[:only] and options[:except] when passed to as_json for the serializable hash' do
        @event[:images] = ['test.jpeg'].to_json
        @event.save!
        @event.reload

        expect(@event.as_json(only: [:foo], except: [:id])).to eq('foo' => nil)
      end

      it 'should respect options[:only] when passed to to_xml for the serializable hash' do
        @event[:images] = ['test.jpeg'].to_json
        @event.save!
        @event.reload

        expect(Hash.from_xml(@event.to_xml(only: [:foo]))["event#{$arclass}"]['images']).to be_nil
      end

      it 'should respect options[:except] when passed to to_xml for the serializable hash' do
        @event[:images] = ['test.jpeg'].to_json
        @event.save!
        @event.reload

        expect(Hash.from_xml(@event.to_xml(except: [:images]))["event#{$arclass}"]['images']).to be_nil
      end

      it 'should respect both options[:only] and options[:except] when passed to to_xml for the serializable hash' do
        @event[:images] = ['test.jpeg'].to_json
        @event.save!
        @event.reload

        expect(Hash.from_xml(@event.to_xml(only: [:foo], except: [:id]))["event#{$arclass}"]['images']).to be_nil
      end
    end

    describe '#images=' do
      it 'should cache a file' do
        @event.images = [stub_file('test.jpeg')]
        expect(@event.images[0]).to be_an_instance_of(@uploader)
      end

      it 'should write nothing to the database, to prevent overriden filenames to fail because of unassigned attributes' do
        expect(@event[:images]).to be_nil
      end

      it 'should copy a file into into the cache directory' do
        @event.images = [stub_file('test.jpeg')]
        expect(@event.images[0].current_path).to match(%r{^#{public_path('uploads/tmp')}})
      end

      it 'should do nothing when nil is assigned' do
        @event.images = nil
        expect(@event.images).to be_empty
      end

      it 'should do nothing when an empty string is assigned' do
        @event.images = ''
        expect(@event.images).to be_empty
      end

      context 'when validating white list integrity' do
        before do
          @uploader.class_eval do
            def extension_white_list
              %w(txt)
            end
          end
        end

        it 'should use I18n for integrity error messages' do
          # Localize the error message to Dutch
          change_locale_and_store_translations(:nl, errors: {
                                                 messages: {
                                                   extension_white_list_error: 'Het opladen van %{extension} bestanden is niet toe gestaan. Geaccepteerde types: %{allowed_types}'
                                                 }
                                               }) do
            # Assigning images triggers check_whitelist! and thus should be inside change_locale_and_store_translations
            @event.images = [stub_file('test.jpg')]
            expect(@event).to_not be_valid
            @event.valid?
            expect(@event.errors[:images]).to eq (['Het opladen van "jpg" bestanden is niet toe gestaan. Geaccepteerde types: txt'])
          end
        end
      end

      context 'when validating black list integrity' do
        before do
          @uploader.class_eval do
            def extension_black_list
              %w(jpg)
            end
          end
        end

        it 'should use I18n for integrity error messages' do
          # Localize the error message to Dutch
          change_locale_and_store_translations(:nl, errors: {
                                                 messages: {
                                                   extension_black_list_error: 'You are not allowed to upload %{extension} files, prohibited types: %{prohibited_types}'
                                                 }
                                               }) do
            # Assigning images triggers check_blacklist! and thus should be inside change_locale_and_store_translations
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
              fail CarrierWave::ProcessingError
            end
          end
          @event.images = [stub_file('test.jpg')]
        end

        it 'should make the record invalid when a processing error occurs' do
          expect(@event).to_not be_valid
        end

        it 'should use I18n for processing errors without messages' do
          @event.valid?
          expect(@event.errors[:images]).to eq(['failed to be processed'])

          change_locale_and_store_translations(:pt, activerecord: {
                                                 errors: {
                                                   messages: {
                                                     carrierwave_processing_error: 'falha ao processar imagesm.'
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
              fail CarrierWave::ProcessingError, 'Ohh noez!'
            end
          end
          @event.images = [stub_file('test.jpg')]
        end

        it 'should make the record invalid when a processing error occurs' do
          expect(@event).to_not be_valid
        end

        it "should use the error's messages for processing errors with messages" do
          @event.valid?
          expect(@event.errors[:images]).to eq(['Ohh noez!'])

          change_locale_and_store_translations(:pt, activerecord: {
                                                 errors: {
                                                   messages: {
                                                     carrierwave_processing_error: 'falha ao processar imagesm.'
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
      it 'should do nothing when no file has been assigned' do
        expect(@event.save).to be_true
        expect(@event.images).to be_empty
      end

      it 'should copy the file to the upload directory when a file has been assigned' do
        @event.images = [stub_file('test.jpeg')]
        expect(@event.save).to be_true
        expect(@event.images[0]).to be_an_instance_of(@uploader)
        expect(@event.images[0].current_path).to eq public_path('uploads/test.jpeg')
      end

      it 'should do nothing when a validation fails' do
        @class.validate { |r| r.errors.add :textfile, 'FAIL!' }
        @event.images = [stub_file('test.jpeg')]
        expect(@event.save).to be_false
        expect(@event.images[0]).to be_an_instance_of(@uploader)
        expect(@event.images[0].current_path).to match(/^#{public_path('uploads/tmp')}/)
      end

      it 'should assign the filename to the database' do
        @event.images = [stub_file('test.jpeg')]
        expect(@event.save).to be_true
        @event.reload
        expect(@event[:images]).to eq(['test.jpeg'])
        expect(@event.images_identifiers[0]).to eq('test.jpeg')
      end

      it 'should preserve the images when nothing is assigned' do
        @event.images = [stub_file('test.jpeg')]
        expect(@event.save).to be_true
        @event = @class.find(@event.id)
        @event.foo = 'bar'
        expect(@event.save).to be_true
        expect(@event[:images]).to eq(['test.jpeg'])
        expect(@event.images_identifiers[0]).to eq('test.jpeg')
      end

      it 'should remove the images if remove_images? returns true' do
        @event.images = [stub_file('test.jpeg')]
        @event.save!
        @event.remove_images = true
        @event.save!
        @event.reload
        expect(@event.images).to be_empty
        expect(@event[:images]).to eq(nil)
        expect(@event.images_identifiers[0]).to eq(nil)
      end

      it 'should mark images as changed when saving a new images' do
        expect(@event.images_changed?).to be_false
        @event.images = [stub_file('test.jpeg')]
        expect(@event.images_changed?).to be_true
        @event.save
        @event.reload
        expect(@event.images_changed?).to be_false
        @event.images = [stub_file('test.jpg')]
        expect(@event.images_changed?).to be_true
        expect(@event.changed_for_autosave?).to be_true
      end
    end

    describe 'remove_images!' do
      before do
        @event.images = [stub_file('test.jpeg')]
        @event.save!
        @event.remove_images!
      end

      it 'should clear the serialization column' do
        expect(@event.attributes['images']).to be_blank
      end

      it 'should return to false after being saved' do
        @event.save!
        @event.remove_images.should == false
        @event.remove_images?.should == false
      end
    end

    describe 'remove_images=' do
      it 'should mark the images as changed if changed' do
        expect(@event.images_changed?).to be_false
        @event.remove_images.should be_nil
        @event.remove_images = '1'
        expect(@event.images_changed?).to be_true
      end
    end

    describe '#remote_images_urls=' do
      # FIXME ideally images_changed? and remote_images_urls_changed? would return true
      it 'should mark images as changed when setting remote_images_urls' do
        expect(@event.images_changed?).to be_false
        @event.remote_images_urls = ['http://www.example.com/test.jpg']
        expect(@event.images_changed?).to be_true
        @event.save!
        @event.reload
        expect(@event.images_changed?).to be_false
      end

      context 'when validating download' do
        before do
          @uploader.class_eval do
            def download!(_file)
              fail CarrierWave::DownloadError
            end
          end
          @event.remote_images_urls = ['http://www.example.com/missing.jpg']
        end

        it 'should make the record invalid when a download error occurs' do
          expect(@event).to_not be_valid
        end

        it 'should use I18n for download errors without messages' do
          @event.valid?
          expect(@event.errors[:images]).to eq(['could not be downloaded'])

          change_locale_and_store_translations(:pt, activerecord: {
                                                 errors: {
                                                   messages: {
                                                     carrierwave_download_error: 'não pode ser descarregado'
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
      it 'should not raise an error with a custom filename' do
        @uploader.class_eval do
          def filename
            'page.jpeg'
          end
        end

        @event.images = [stub_file('test.jpeg')]
        expect(@event.save).to be_true
        expect do
          @event.destroy
        end.to_not raise_error
      end

      it 'should do nothing when no file has been assigned' do
        expect(@event.save).to be_true
        @event.destroy
      end

      it 'should remove the file from the filesystem' do
        @event.images = [stub_file('test.jpeg')]
        expect(@event.save).to be_true
        expect(@event.images[0]).to be_an_instance_of(@uploader)
        expect(@event.images[0].current_path).to eq public_path('uploads/test.jpeg')
        @event.destroy
        expect(File.exist?(public_path('uploads/test.jpeg'))).to be_false
      end
    end

    describe 'with overriddent filename' do
      describe '#save' do
        before do
          @uploader.class_eval do
            def filename
              model.name + File.extname(super)
            end
          end
          @event.stub(:name).and_return('jonas')
        end

        it 'should copy the file to the upload directory when a file has been assigned' do
          @event.images = [stub_file('test.jpeg')]
          expect(@event.save).to be_true
          expect(@event.images[0]).to be_an_instance_of(@uploader)
          expect(@event.images[0].current_path).to eq(public_path('uploads/jonas.jpeg'))
        end

        it 'should assign an overridden filename to the database' do
          @event.images = [stub_file('test.jpeg')]
          expect(@event.save).to be_true
          @event.reload
          expect(@event[:images]).to eq(['jonas.jpeg'])
        end
      end
    end

    describe 'with validates_presence_of' do
      before do
        @class.validates_presence_of :images
        @event.stub(:name).and_return('jonas')
      end

      it 'should be valid if a file has been cached' do
        @event.images = [stub_file('test.jpeg')]
        expect(@event).to be_valid
      end

      it 'should not be valid if a file has not been cached' do
        expect(@event).to_not be_valid
      end
    end

    describe 'with validates_size_of' do
      before do
        @class.validates_size_of :images, maximum: 2
        @event.stub(:name).and_return('jonas')
      end

      it 'should be valid if at the number criteria are met' do
        @event.images = [stub_file('test.jpeg'), stub_file('old.jpeg')]
        expect(@event).to be_valid
      end

      it 'should be invalid if size criteria are exceeded' do
        @event.images = [stub_file('test.jpeg'), stub_file('old.jpeg'), stub_file('new.jpeg')]
        expect(@event).to_not be_valid
      end
    end
  end

  describe '#mount_uploaders with mount_on' do
    before do
      @class = Class.new(Event)
      @class.table_name = 'events'
      @uploader = Class.new(CarrierWave::Uploader::Base)
      @class.mount_uploaders(:avatar, @uploader, mount_on: :images)
      @event = @class.new
    end

    describe '#avatar=' do
      it 'should cache a file' do
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
      @class = Class.new(Event)
      @class.table_name = 'events'
      @uploader = Class.new(CarrierWave::Uploader::Base)
      @class.mount_uploaders(:images, @uploader)
      @event = @class.new
      @event.images = [stub_file('old.jpeg')]
      expect(@event.save).to be_true
      expect(File.exist?(public_path('uploads/old.jpeg'))).to be_true
    end

    after do
      FileUtils.rm_rf(file_path('uploads'))
    end

    describe 'normally' do
      it 'should remove old file if old file had a different path' do
        @event.images = [stub_file('new.jpeg')]
        expect(@event.save).to be_true
        expect(File.exist?(public_path('uploads/new.jpeg'))).to be_true
        expect(File.exist?(public_path('uploads/old.jpeg'))).to be_false
      end

      it 'should not remove old file if old file had a different path but config is false' do
        @uploader.stub(:remove_previously_stored_files_after_update).and_return(false)
        @event.images = [stub_file('new.jpeg')]
        expect(@event.save).to be_true
        expect(File.exist?(public_path('uploads/new.jpeg'))).to be_true
        expect(File.exist?(public_path('uploads/old.jpeg'))).to be_true
      end

      it 'should not remove file if old file had the same path' do
        @event.images = [stub_file('old.jpeg')]
        expect(@event.save).to be_true
        expect(File.exist?(public_path('uploads/old.jpeg'))).to be_true
      end

      it 'should not remove file if validations fail on save' do
        @class.validate { |r| r.errors.add :textfile, 'FAIL!' }
        @event.images = [stub_file('new.jpeg')]
        expect(@event.save).to be_false
        expect(File.exist?(public_path('uploads/old.jpeg'))).to be_true
      end
    end

    describe 'with an overriden filename' do
      before do
        @uploader.class_eval do
          def filename
            model.foo + File.extname(super)
          end
        end

        @event.images = [stub_file('old.jpeg')]
        @event.foo = 'test'
        expect(@event.save).to be_true
        expect(File.exist?(public_path('uploads/test.jpeg'))).to be_true
        expect(@event.images[0].read).to eq('this is stuff')
      end

      it 'should not remove file if old file had the same dynamic path' do
        @event.images = [stub_file('test.jpeg')]
        expect(@event.save).to be_true
        expect(File.exist?(public_path('uploads/test.jpeg'))).to be_true
      end

      it 'should remove old file if old file had a different dynamic path' do
        @event.foo = 'new'
        @event.images = [stub_file('test.jpeg')]
        expect(@event.save).to be_true
        expect(File.exist?(public_path('uploads/new.jpeg'))).to be_true
        expect(File.exist?(public_path('uploads/test.jpeg'))).to be_false
      end
    end
  end

  describe '#mount_uploaders removing old files with versions' do
    before do
      @class = Class.new(Event)
      @class.table_name = 'events'
      @uploader = Class.new(CarrierWave::Uploader::Base)
      @uploader.version :thumb
      @class.mount_uploaders(:images, @uploader)
      @event = @class.new
      @event.images = [stub_file('old.jpeg')]
      expect(@event.save).to be_true
      expect(File.exist?(public_path('uploads/old.jpeg'))).to be_true
      expect(File.exist?(public_path('uploads/thumb_old.jpeg'))).to be_true
    end

    after do
      FileUtils.rm_rf(file_path('uploads'))
    end

    it 'should remove old file if old file had a different path' do
      @event.images = [stub_file('new.jpeg')]
      expect(@event.save).to be_true
      expect(File.exist?(public_path('uploads/new.jpeg'))).to be_true
      expect(File.exist?(public_path('uploads/thumb_new.jpeg'))).to be_true
      expect(File.exist?(public_path('uploads/old.jpeg'))).to be_false
      expect(File.exist?(public_path('uploads/thumb_old.jpeg'))).to be_false
    end

    it 'should not remove file if old file had the same path' do
      @event.images = [stub_file('old.jpeg')]
      expect(@event.save).to be_true
      expect(File.exist?(public_path('uploads/old.jpeg'))).to be_true
      expect(File.exist?(public_path('uploads/thumb_old.jpeg'))).to be_true
    end
  end

  describe '#mount_uploaders removing old files with multiple uploaders' do
    before do
      @class = Class.new(Event)
      @class.table_name = 'events'
      @uploader = Class.new(CarrierWave::Uploader::Base)
      @class.mount_uploaders(:images, @uploader)
      @uploader1 = Class.new(CarrierWave::Uploader::Base)
      @class.mount_uploaders(:textfiles, @uploader1)
      @event = @class.new
      @event.images = [stub_file('old.jpeg')]
      @event.textfiles = [stub_file('old.txt')]
      expect(@event.save).to be_true
      expect(File.exist?(public_path('uploads/old.jpeg'))).to be_true
      expect(File.exist?(public_path('uploads/old.txt'))).to be_true
    end

    after do
      FileUtils.rm_rf(file_path('uploads'))
    end

    it 'should remove old file1 and file2 if old file1 and file2 had a different paths' do
      @event.images = [stub_file('new.jpeg')]
      @event.textfiles = [stub_file('new.txt')]
      expect(@event.save).to be_true
      expect(File.exist?(public_path('uploads/new.jpeg'))).to be_true
      expect(File.exist?(public_path('uploads/old.jpeg'))).to be_false
      expect(File.exist?(public_path('uploads/new.txt'))).to be_true
      expect(File.exist?(public_path('uploads/old.txt'))).to be_false
    end

    it 'should remove old file1 but not file2 if old file1 had a different path but old file2 has the same path' do
      @event.images = [stub_file('new.jpeg')]
      @event.textfiles = [stub_file('old.txt')]
      expect(@event.save).to be_true
      expect(File.exist?(public_path('uploads/new.jpeg'))).to be_true
      expect(File.exist?(public_path('uploads/old.jpeg'))).to be_false
      expect(File.exist?(public_path('uploads/old.txt'))).to be_true
    end

    it 'should not remove file1 or file2 if file1 and file2 have the same paths' do
      @event.images = [stub_file('old.jpeg')]
      @event.textfiles = [stub_file('old.txt')]
      expect(@event.save).to be_true
      expect(File.exist?(public_path('uploads/old.jpeg'))).to be_true
      expect(File.exist?(public_path('uploads/old.txt'))).to be_true
    end
  end

  describe '#mount_uploaders removing old files with with mount_on' do
    before do
      @class = Class.new(Event)
      @class.table_name = 'events'
      @uploader = Class.new(CarrierWave::Uploader::Base)
      @class.mount_uploaders(:avatar, @uploader, mount_on: :images)
      @event = @class.new
      @event.avatar = [stub_file('old.jpeg')]
      expect(@event.save).to be_true
      expect(File.exist?(public_path('uploads/old.jpeg'))).to be_true
    end

    after do
      FileUtils.rm_rf(file_path('uploads'))
    end

    it 'should remove old file if old file had a different path' do
      @event.avatar = [stub_file('new.jpeg')]
      expect(@event.save).to be_true
      expect(File.exist?(public_path('uploads/new.jpeg'))).to be_true
      expect(File.exist?(public_path('uploads/old.jpeg'))).to be_false
    end

    it 'should not remove file if old file had the same path' do
      @event.avatar = [stub_file('old.jpeg')]
      expect(@event.save).to be_true
      expect(File.exist?(public_path('uploads/old.jpeg'))).to be_true
    end
  end
end
