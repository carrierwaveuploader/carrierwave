# encoding: utf-8

require 'spec_helper'

describe CarrierWave::Uploader do

  before do
    @uploader_class = Class.new(CarrierWave::Uploader::Base)
    @uploader = @uploader_class.new
  end

  after do
    FileUtils.rm_rf(public_path)
  end

  describe '#rename!' do
    before do
      @model = mock('a model')
      @model.stub!(:_mounter).with(nil).and_return(Struct.new(:identifier).new)

      @file = File.open(file_path('test.jpg'))

      @stored_file = mock('a stored file')
      @stored_file.stub!(:path).and_return('/path/to/somewhere')
      @stored_file.stub!(:url).and_return('http://www.example.com')
      @stored_file.stub!(:identifier).and_return('this-is-me')
      @stored_file.stub!(:rename)

      @storage = mock('a storage engine')
      @storage.stub!(:store!).and_return(@stored_file)

      @uploader_class.storage.stub!(:new).and_return(@storage)
      @uploader.store!(@file)
      @uploader.stub!(:model).and_return(@model)
    end

    it "should not be renamed" do
       @stored_file.should_not_receive(:rename!)
       @uploader.rename!
     end

    describe 'with stale model' do

      before do
        @uploader_class.class_eval do
          def stale_model?
            true
          end
        end
      end

      it 'should be renamed' do
        @storage.should_receive(:rename!).with(@stored_file)
        @uploader.send(:check_stale_model!)
        @uploader.rename!
      end

    end

  end

end
