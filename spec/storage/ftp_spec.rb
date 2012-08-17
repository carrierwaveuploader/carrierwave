# encoding: utf-8

require 'spec_helper'

class FtpUploader < CarrierWave::Uploader::Base
  storage :ftp
end

describe CarrierWave::Storage::FTP do
  before do
    CarrierWave.configure do |config|
      config.reset_config
      config.ftp_host = 'ftp.testcarrierwave.dev'
      config.ftp_user = 'test_user'
      config.ftp_passwd = 'test_passwd'
      config.ftp_folder = '~/public_html'
      config.ftp_url = 'http://testcarrierwave.dev'
    end

    @file = CarrierWave::SanitizedFile.new(file_path('test.jpg'))
    FtpUploader.stub!(:store_path).and_return('uploads/test.jpg')
    @storage = CarrierWave::Storage::FTP.new(FtpUploader)
  end

  it "opens/closes an ftp connection to the given host" do
    ftp = double(:ftp_connection)
    ftp_params = [
      'ftp.testcarrierwave.dev',
      'test_user',
      'test_passwd'
    ]

    Net::FTP.should_receive(:open).with(*ftp_params).and_return(ftp)
    ftp.should_receive(:mkdir_p).with('~/public_html/uploads')
    ftp.should_receive(:chdir).with('~/public_html/uploads')
    ftp.should_receive(:put).with(@file.path, 'test.jpg')
    ftp.should_receive(:close)
    @stored = @storage.store!(@file)
  end

  describe 'after upload' do
    before do
      ftp = double(:ftp_connection)
      Net::FTP.stub(:open).and_return(ftp)
      ftp.stub(:mkdir_p)
      ftp.stub(:chdir)
      ftp.stub(:put)
      ftp.stub(:close)
      @stored = @storage.store!(@file)
    end

    it "returns a url based on directory" do
      @stored.url.should == 'http://testcarrierwave.dev/uploads/test.jpg'
    end

    it "returns a path based on directory" do
      @stored.path.should == 'uploads/test.jpg'
    end
  end

  describe 'other operations' do
    before do
      @ftp = double(:ftp_connection)
      Net::FTP.stub(:open).and_return(@ftp)
      @ftp.stub(:mkdir_p)
      @ftp.stub(:chdir)
      @ftp.stub(:put)
      @ftp.stub(:close)
      @stored = @storage.store!(@file)
    end

    it "deletes a file" do
      @ftp.should_receive(:chdir).with('~/public_html/uploads')
      @ftp.should_receive(:delete).with('test.jpg')
      @stored.delete
    end

    it "checks whether a file exists" do
      @stored.should_receive(:size).and_return(10)
      @stored.exists?.should == true
    end

    it "returns the size of the file" do
      @ftp.should_receive(:size).and_return(14)
      @stored.size.should == 14
    end

    it "returns the content of the file" do
      @stored.should_receive(:http_get_body).with(@stored.url).and_return('some content')
      @stored.read.should == 'some content'
    end
  end
end
