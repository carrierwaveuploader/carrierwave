# encoding: utf-8

require 'spec_helper'

require 'carrierwave/orm/activerecord'

# change this if sqlite is unavailable
dbconfig = {
  :adapter => 'sqlite3',
  :database => ':memory:'
}

ActiveRecord::Base.establish_connection(dbconfig)
ActiveRecord::Migration.verbose = false

class TestMigration < ActiveRecord::Migration
  def self.up
    create_table :events, :force => true do |t|
      t.column :image, :string
      t.column :textfile, :string
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

  describe '#mount_uploader' do

    before(:all) { TestMigration.up }
    after(:all) { TestMigration.down }
    after { Event.delete_all }

    before do
      # My god, what a horrible, horrible solution, but AR validations don't work
      # unless the class has a name. This is the best I could come up with :S
      $arclass += 1
      @class = Class.new(Event)
      # AR validations don't work unless the class has a name, and
      # anonymous classes can be named by assigning them to a constant
      Object.const_set("Event#{$arclass}", @class)
      @class.table_name = "events"
      @uploader = Class.new(CarrierWave::Uploader::Base)
      @class.mount_uploader(:image, @uploader)
      @event = @class.new
    end

    describe '#image' do

      it "should return blank uploader when nothing has been assigned" do
        @event.image.should be_blank
      end

      it "should return blank uploader when an empty string has been assigned" do
        @event[:image] = ''
        @event.save
        @event.reload
        @event.image.should be_blank
      end

      it "should retrieve a file from the storage if a value is stored in the database" do
        @event[:image] = 'test.jpeg'
        @event.save
        @event.reload
        @event.image.should be_an_instance_of(@uploader)
      end

      it "should set the path to the store dir" do
        @event[:image] = 'test.jpeg'
        @event.save
        @event.reload
        @event.image.current_path.should == public_path('uploads/test.jpeg')
      end

      it "should return valid JSON when to_json is called when image is nil" do
        @event[:image].should be_nil

        JSON.parse(@event.to_json)["event#{$arclass}"]["image"].should == {"url"=>nil}
      end

      it "should return valid JSON when to_json is called when image is present" do
        @event[:image] = 'test.jpeg'
        @event.save
        @event.reload

        JSON.parse(@event.to_json)["event#{$arclass}"]["image"].should == {"url"=>"/uploads/test.jpeg"}
      end

      # FIXME to_xml should work like to_json
      it "should return valid XML when to_xml is called when image is nil" do
        @event[:image].should be_nil

        Hash.from_xml(@event.to_xml)["event#{$arclass}"].except("id").should == {"textfile"=>nil, "foo"=>nil}
      end

      # FIXME to_xml should work like to_json
      it "should return valid XML when to_xml is called when image is present" do
        @event[:image] = 'test.jpeg'
        @event.save
        @event.reload

        Hash.from_xml(@event.to_xml)["event#{$arclass}"]["image"].should == "test.jpeg"
      end
    end

    describe '#image=' do

      it "should cache a file" do
        @event.image = stub_file('test.jpeg')
        @event.image.should be_an_instance_of(@uploader)
      end

      it "should write nothing to the database, to prevent overriden filenames to fail because of unassigned attributes" do
        @event[:image].should be_nil
      end

      it "should copy a file into into the cache directory" do
        @event.image = stub_file('test.jpeg')
        @event.image.current_path.should =~ %r(^#{public_path('uploads/tmp')})
      end

      it "should do nothing when nil is assigned" do
        @event.image = nil
        @event.image.should be_blank
      end

      it "should do nothing when an empty string is assigned" do
        @event.image = ''
        @event.image.should be_blank
      end

      context 'when validating integrity' do
        before do
          @uploader.class_eval do
            def extension_white_list
              %w(txt)
            end
          end
        end

        it "should use I18n for integrity error messages" do
          # Localize the error message to Dutch
          change_locale_and_store_translations(:nl, :errors => {
            :messages => {
              :extension_white_list_error => "Het opladen van %{extension} bestanden is niet toe gestaan. Geaccepteerde types: %{allowed_types}"
            }
          }) do
            # Assigning image triggers check_whitelist! and thus should be inside change_locale_and_store_translations
            @event.image = stub_file('test.jpg')
            @event.should_not be_valid
            @event.valid?
            @event.errors[:image].should == ['Het opladen van "jpg" bestanden is niet toe gestaan. Geaccepteerde types: ["txt"]']
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
          @event.should_not be_valid
        end

        it "should use I18n for processing errors without messages" do
          @event.valid?
          @event.errors[:image].should == ['failed to be processed']

          change_locale_and_store_translations(:pt, :activerecord => {
            :errors => {
              :messages => {
                :carrierwave_processing_error => 'falha ao processar imagem.'
              }
            }
          }) do
            @event.should_not be_valid
            @event.errors[:image].should == ['falha ao processar imagem.']
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
          @event.image = stub_file('test.jpg')
        end

        it "should make the record invalid when a processing error occurs" do
          @event.should_not be_valid
        end

        it "should use the error's messages for processing errors with messages" do
          @event.valid?
          @event.errors[:image].should == ['Ohh noez!']

          change_locale_and_store_translations(:pt, :activerecord => {
            :errors => {
              :messages => {
                :carrierwave_processing_error => 'falha ao processar imagem.'
              }
            }
          }) do
            @event.should_not be_valid
            @event.errors[:image].should == ['Ohh noez!']
          end
        end
      end
    end

    describe '#save' do

      it "should do nothing when no file has been assigned" do
        @event.save.should be_true
        @event.image.should be_blank
      end

      it "should copy the file to the upload directory when a file has been assigned" do
        @event.image = stub_file('test.jpeg')
        @event.save.should be_true
        @event.image.should be_an_instance_of(@uploader)
        @event.image.current_path.should == public_path('uploads/test.jpeg')
      end

      it "should do nothing when a validation fails" do
        @class.validate { |r| r.errors.add :textfile, "FAIL!" }
        @event.image = stub_file('test.jpeg')
        @event.save.should be_false
        @event.image.should be_an_instance_of(@uploader)
        @event.image.current_path.should =~ /^#{public_path('uploads/tmp')}/
      end

      it "should assign the filename to the database" do
        @event.image = stub_file('test.jpeg')
        @event.save.should be_true
        @event.reload
        @event[:image].should == 'test.jpeg'
        @event.image_identifier.should == 'test.jpeg'
      end

      it "should preserve the image when nothing is assigned" do
        @event.image = stub_file('test.jpeg')
        @event.save.should be_true
        @event = @class.find(@event.id)
        @event.foo = "bar"
        @event.save.should be_true
        @event[:image].should == 'test.jpeg'
        @event.image_identifier.should == 'test.jpeg'
      end

      it "should remove the image if remove_image? returns true" do
        @event.image = stub_file('test.jpeg')
        @event.save!
        @event.remove_image = true
        @event.save!
        @event.reload
        @event.image.should be_blank
        @event[:image].should == ''
        @event.image_identifier.should == ''
      end

      it "should mark image as changed when saving a new image" do
        @event.image_changed?.should be_false
        @event.image = stub_file("test.jpeg")
        @event.image_changed?.should be_true
        @event.save
        @event.reload
        @event.image_changed?.should be_false
        @event.image = stub_file("test.jpg")
        @event.image_changed?.should be_true
        @event.changed_for_autosave?.should be_true
      end
    end

    describe "dirty tracking with remote_image_url" do

      # FIXME ideally image_changed? and remote_image_url_changed? would return true
      it "should mark image as changed when setting remote_image_url" do
        @event.image_changed?.should be_false
        @event.remote_image_url = 'http://www.example.com/test.jpg'
        @event.image_changed?.should be_true
        @event.save
        @event.reload
        @event.image_changed?.should be_false
      end

    end

    describe '#destroy' do

      it "should do nothing when no file has been assigned" do
        @event.save.should be_true
        @event.destroy
      end

      it "should remove the file from the filesystem" do
        @event.image = stub_file('test.jpeg')
        @event.save.should be_true
        @event.image.should be_an_instance_of(@uploader)
        @event.image.current_path.should == public_path('uploads/test.jpeg')
        @event.destroy
        File.exist?(public_path('uploads/test.jpeg')).should be_false
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
          @event.stub!(:name).and_return('jonas')
        end

        it "should copy the file to the upload directory when a file has been assigned" do
          @event.image = stub_file('test.jpeg')
          @event.save.should be_true
          @event.image.should be_an_instance_of(@uploader)
          @event.image.current_path.should == public_path('uploads/jonas.jpeg')
        end

        it "should assign an overridden filename to the database" do
          @event.image = stub_file('test.jpeg')
          @event.save.should be_true
          @event.reload
          @event[:image].should == 'jonas.jpeg'
        end

      end

    end

    describe 'with validates_presence_of' do

      before do
        @class.validates_presence_of :image
        @event.stub!(:name).and_return('jonas')
      end

      it "should be valid if a file has been cached" do
        @event.image = stub_file('test.jpeg')
        @event.should be_valid
      end

      it "should not be valid if a file has not been cached" do
        @event.should_not be_valid
      end

    end

    describe 'with validates_size_of' do

      before do
        @class.validates_size_of :image, :maximum => 40
        @event.stub!(:name).and_return('jonas')
      end

      it "should be valid if a file has been cached that matches the size criteria" do
        @event.image = stub_file('test.jpeg')
        @event.should be_valid
      end

      it "should not be valid if a file has been cached that does not match the size criteria" do
        @event.image = stub_file('bork.txt')
        @event.should_not be_valid
      end

    end
  end

  describe '#mount_uploader with mount_on' do

    before(:all) { TestMigration.up }
    after(:all) { TestMigration.down }
    after { Event.delete_all }

    before do
      @class = Class.new(Event)
      @class.table_name = "events"
      @uploader = Class.new(CarrierWave::Uploader::Base)
      @class.mount_uploader(:avatar, @uploader, :mount_on => :image)
      @event = @class.new
    end

    describe '#avatar=' do

      it "should cache a file" do
        @event.avatar = stub_file('test.jpeg')
        @event.save
        @event.reload
        @event.avatar.should be_an_instance_of(@uploader)
        @event.image.should == 'test.jpeg'
      end

    end
  end

  describe '#mount_uploader removing old files' do

    before(:all) { TestMigration.up }
    after(:all) { TestMigration.down }

    before do
      @class = Class.new(Event)
      @class.table_name = "events"
      @uploader = Class.new(CarrierWave::Uploader::Base)
      @class.mount_uploader(:image, @uploader)
      @event = @class.new
      @event.image = stub_file('old.jpeg')
      @event.save.should be_true
      File.exists?(public_path('uploads/old.jpeg')).should be_true
    end

    after do
      FileUtils.rm_rf(file_path("uploads"))
    end

    describe 'normally' do
      it "should remove old file if old file had a different path" do
        @event.image = stub_file('new.jpeg')
        @event.save.should be_true
        File.exists?(public_path('uploads/new.jpeg')).should be_true
        File.exists?(public_path('uploads/old.jpeg')).should be_false
      end

      it "should not remove old file if old file had a different path but config is false" do
        @uploader.stub!(:remove_previously_stored_files_after_update).and_return(false)
        @event.image = stub_file('new.jpeg')
        @event.save.should be_true
        File.exists?(public_path('uploads/new.jpeg')).should be_true
        File.exists?(public_path('uploads/old.jpeg')).should be_true
      end

      it "should not remove file if old file had the same path" do
        @event.image = stub_file('old.jpeg')
        @event.save.should be_true
        File.exists?(public_path('uploads/old.jpeg')).should be_true
      end

      it "should not remove file if validations fail on save" do
        @class.validate { |r| r.errors.add :textfile, "FAIL!" }
        @event.image = stub_file('new.jpeg')
        @event.save.should be_false
        File.exists?(public_path('uploads/old.jpeg')).should be_true
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
        @event.foo = "test"
        @event.save.should be_true
        File.exists?(public_path('uploads/test.jpeg')).should be_true
        @event.image.read.should == "this is stuff"
      end

      it "should not remove file if old file had the same dynamic path" do
        @event.image = stub_file('test.jpeg')
        @event.save.should be_true
        File.exists?(public_path('uploads/test.jpeg')).should be_true
      end

      it "should remove old file if old file had a different dynamic path" do
        @event.foo = "new"
        @event.image = stub_file('test.jpeg')
        @event.save.should be_true
        File.exists?(public_path('uploads/new.jpeg')).should be_true
        File.exists?(public_path('uploads/test.jpeg')).should be_false
      end
    end
  end

  describe '#mount_uploader removing old files with versions' do

    before(:all) { TestMigration.up }
    after(:all) { TestMigration.down }

    before do
      @class = Class.new(Event)
      @class.table_name = "events"
      @uploader = Class.new(CarrierWave::Uploader::Base)
      @uploader.version :thumb
      @class.mount_uploader(:image, @uploader)
      @event = @class.new
      @event.image = stub_file('old.jpeg')
      @event.save.should be_true
      File.exists?(public_path('uploads/old.jpeg')).should be_true
      File.exists?(public_path('uploads/thumb_old.jpeg')).should be_true
    end

    after do
      FileUtils.rm_rf(file_path("uploads"))
    end

    it "should remove old file if old file had a different path" do
      @event.image = stub_file('new.jpeg')
      @event.save.should be_true
      File.exists?(public_path('uploads/new.jpeg')).should be_true
      File.exists?(public_path('uploads/thumb_new.jpeg')).should be_true
      File.exists?(public_path('uploads/old.jpeg')).should be_false
      File.exists?(public_path('uploads/thumb_old.jpeg')).should be_false
    end

    it "should not remove file if old file had the same path" do
      @event.image = stub_file('old.jpeg')
      @event.save.should be_true
      File.exists?(public_path('uploads/old.jpeg')).should be_true
      File.exists?(public_path('uploads/thumb_old.jpeg')).should be_true
    end
  end

  describe '#mount_uploader removing old files with multiple uploaders' do

    before(:all) { TestMigration.up }
    after(:all) { TestMigration.down }

    before do
      @class = Class.new(Event)
      @class.table_name = "events"
      @uploader = Class.new(CarrierWave::Uploader::Base)
      @class.mount_uploader(:image, @uploader)
      @uploader1 = Class.new(CarrierWave::Uploader::Base)
      @class.mount_uploader(:textfile, @uploader1)
      @event = @class.new
      @event.image = stub_file('old.jpeg')
      @event.textfile = stub_file('old.txt')
      @event.save.should be_true
      File.exists?(public_path('uploads/old.jpeg')).should be_true
      File.exists?(public_path('uploads/old.txt')).should be_true
    end

    after do
      FileUtils.rm_rf(file_path("uploads"))
    end

    it "should remove old file1 and file2 if old file1 and file2 had a different paths" do
      @event.image = stub_file('new.jpeg')
      @event.textfile = stub_file('new.txt')
      @event.save.should be_true
      File.exists?(public_path('uploads/new.jpeg')).should be_true
      File.exists?(public_path('uploads/old.jpeg')).should be_false
      File.exists?(public_path('uploads/new.txt')).should be_true
      File.exists?(public_path('uploads/old.txt')).should be_false
    end

    it "should remove old file1 but not file2 if old file1 had a different path but old file2 has the same path" do
      @event.image = stub_file('new.jpeg')
      @event.textfile = stub_file('old.txt')
      @event.save.should be_true
      File.exists?(public_path('uploads/new.jpeg')).should be_true
      File.exists?(public_path('uploads/old.jpeg')).should be_false
      File.exists?(public_path('uploads/old.txt')).should be_true
    end

    it "should not remove file1 or file2 if file1 and file2 have the same paths" do
      @event.image = stub_file('old.jpeg')
      @event.textfile = stub_file('old.txt')
      @event.save.should be_true
      File.exists?(public_path('uploads/old.jpeg')).should be_true
      File.exists?(public_path('uploads/old.txt')).should be_true
    end
  end

  describe '#mount_uploader removing old files with with mount_on' do

    before(:all) { TestMigration.up }
    after(:all) { TestMigration.down }

    before do
      @class = Class.new(Event)
      @class.table_name = "events"
      @uploader = Class.new(CarrierWave::Uploader::Base)
      @class.mount_uploader(:avatar, @uploader, :mount_on => :image)
      @event = @class.new
      @event.avatar = stub_file('old.jpeg')
      @event.save.should be_true
      File.exists?(public_path('uploads/old.jpeg')).should be_true
    end

    after do
      FileUtils.rm_rf(file_path("uploads"))
    end

    it "should remove old file if old file had a different path" do
      @event.avatar = stub_file('new.jpeg')
      @event.save.should be_true
      File.exists?(public_path('uploads/new.jpeg')).should be_true
      File.exists?(public_path('uploads/old.jpeg')).should be_false
    end

    it "should not remove file if old file had the same path" do
      @event.avatar = stub_file('old.jpeg')
      @event.save.should be_true
      File.exists?(public_path('uploads/old.jpeg')).should be_true
    end
  end
end
