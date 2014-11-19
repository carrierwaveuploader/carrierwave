require 'spec_helper'
require 'generator_spec'
require 'generators/uploader_generator'

describe UploaderGenerator, :type => :generator do
  destination File.expand_path("../../tmp", __FILE__)

  before :each do
    prepare_destination
  end

  it "should properly create uploader file" do
    run_generator %w(Avatar)
    assert_file 'app/uploaders/avatar_uploader.rb', /class AvatarUploader < CarrierWave::Uploader::Base/
  end

  it "should properly create namespaced uploader file" do
    run_generator %w(MyModule::Avatar)
    assert_file 'app/uploaders/my_module/avatar_uploader.rb', /class MyModule::AvatarUploader < CarrierWave::Uploader::Base/
  end
end