# encoding: utf-8
require 'spec_helper'

require 'carrierwave/orm/mongoid'

connection = Mongo::Connection.new
Mongoid.database = connection.db("carrierwave_test")


def reset_mongo_class(uploader = MongoUploader)
  class_name = 'MongoUser'
  Object.send(:remove_const, class_name) rescue nil
  klass = Object.const_set(class_name, Class.new)
  klass.class_eval do
    include Mongoid::Document
    store_in :users
    mount_uploader :image, uploader
  end
  klass
end

class MongoUploader < CarrierWave::Uploader::Base; end

class WhiteListUploader < CarrierWave::Uploader::Base
  def extension_white_list
    %w(txt)
  end
end

class ProcessingErrorUploader < CarrierWave::Uploader::Base
  process :monkey
  def monkey
    raise CarrierWave::ProcessingError, "Ohh noez!"
  end
  def extension_white_list
    %w(jpg)
  end
end


describe CarrierWave::Mongoid do

  after do
    MongoUser.collection.drop
  end

  describe '#image' do

    context "when nothing is assigned" do

      before do
        mongo_user_klass = reset_mongo_class
        @document = mongo_user_klass.new
      end

      it "returns a blank uploader" do
        @document.image.should be_blank
      end

    end

    context "when an empty string is assigned" do

      before do
        mongo_user_klass = reset_mongo_class
        @document = mongo_user_klass.new(:image_filename => "")
        @document.save
      end

      it "returns a blank uploader" do
        @saved_doc = MongoUser.first
        @saved_doc.image.should be_blank
      end

    end

    context "when a filename is saved in the database" do

      before do
        mongo_user_klass = reset_mongo_class
        @document = mongo_user_klass.new(:image_filename => "test.jpg")
        @document.save
        @doc = MongoUser.first
      end

      it "returns an uploader" do
        @doc.image.should be_an_instance_of(MongoUploader)
      end

      it "sets the path to the store directory" do
        @doc.image.current_path.should == public_path('uploads/test.jpg')
      end

    end

  end

  describe '#image=' do

    before do
      mongo_user_klass = reset_mongo_class
      @doc = mongo_user_klass.new
    end

    context "when nil is assigned" do

      it "does not set the value" do
        @doc.image = nil
        @doc.image.should be_blank
      end

    end

    context "when an empty string is assigned" do

      it "does not set the value" do
        @doc.image = ''
        @doc.image.should be_blank
      end

    end

    context "when a file is assigned" do

      it "should cache a file" do
        @doc.image = stub_file('test.jpeg')
        @doc.image.should be_an_instance_of(MongoUploader)
      end

      it "should write nothing to the database, to prevent overriden filenames to fail because of unassigned attributes" do
        @doc.image_filename.should be_nil
      end

      it "should copy a file into into the cache directory" do
        @doc.image = stub_file('test.jpeg')
        @doc.image.current_path.should =~ /^#{public_path('uploads\/tmp')}/
      end

    end

    context 'when validating integrity' do
      before do
        mongo_user_klass = reset_mongo_class(WhiteListUploader)
        @doc = mongo_user_klass.new
        @doc.image = stub_file('test.jpg')
      end

      it "should make the document invalid when an integrity error occurs" do
        @doc.should_not be_valid
      end

      it "should use I18n for integrity error messages" do
        @doc.valid?
        @doc.errors[:image].should == ['is not an allowed file type']

        change_locale_and_store_translations(:pt, :activemodel => {
          :errors => {
            :messages => {
              :carrierwave_integrity_error => 'tipo de imagem não permitido.'
            }
          }
        }) do
          @doc.should_not be_valid
          @doc.errors[:image].should == ['tipo de imagem não permitido.']
        end
      end
    end

    context 'when validating processing' do
      before do
        mongo_user_klass = reset_mongo_class(ProcessingErrorUploader)
        @doc = mongo_user_klass.new
        @doc.image = stub_file('test.jpg')
      end

      it "should make the document invalid when a processing error occurs" do
        @doc.should_not be_valid
      end

      it "should use I18n for processing error messages" do
        @doc.valid?
        @doc.errors[:image].should == ['failed to be processed']

        change_locale_and_store_translations(:pt, :activemodel => {
          :errors => {
            :messages => {
              :carrierwave_processing_error => 'falha ao processar imagem.'
            }
          }
        }) do
          @doc.should_not be_valid
          @doc.errors[:image].should == ['falha ao processar imagem.']
        end
      end
    end

  end

  describe "#save" do

    before do
      mongo_user_klass = reset_mongo_class
      @doc = mongo_user_klass.new
    end

    context "when no file is assigned" do

      it "image is blank" do
        @doc.save
        @doc.image.should be_blank
      end

    end

    context "when a file is assigned" do

      it "copies the file to the upload directory" do
        @doc.image = stub_file('test.jpg')
        @doc.save
        @doc.image.should be_an_instance_of(MongoUploader)
        @doc.image.current_path.should == public_path('uploads/test.jpg')
      end

      it "saves the filename in the database" do
        @doc.image = stub_file('test.jpg')
        @doc.save
        @doc.image_filename.should == 'test.jpg'
      end

      context "when remove_image? is true" do

        it "removes the image" do
          @doc.image = stub_file('test.jpeg')
          @doc.save
          @doc.remove_image = true
          @doc.save
          @doc.reload
          @doc.image.should be_blank
          @doc.image_filename.should == ''
        end

      end

    end

  end

  describe '#destroy' do

    before do
      mongo_user_klass = reset_mongo_class
      @doc = mongo_user_klass.new
    end

    describe "when file assigned" do

      it "removes the file from the filesystem" do
        @doc.image = stub_file('test.jpeg')
        @doc.save.should be_true
        File.exist?(public_path('uploads/test.jpeg')).should be_true
        @doc.image.should be_an_instance_of(MongoUploader)
        @doc.image.current_path.should == public_path('uploads/test.jpeg')
        @doc.destroy
        File.exist?(public_path('uploads/test.jpeg')).should be_false
      end

    end

    describe "when file is not assigned" do

      it "deletes the instance of MongoUser after save" do
        @doc.save
        MongoUser.count.should eql(1)
        @doc.destroy
      end

      it "deletes the instance of MongoUser after save and then re-looking up the instance" do
        @doc.save
        MongoUser.count.should eql(1)
        @doc = MongoUser.first
        @doc.destroy
      end

    end

  end


end
