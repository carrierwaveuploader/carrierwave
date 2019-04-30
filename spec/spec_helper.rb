# encoding: utf-8

require 'rubygems'
require 'bundler/setup'

require 'tempfile'
require 'time'
require 'logger'

require 'carrierwave'
require 'timecop'
require 'open-uri'
require 'sham_rack'
require 'mini_magick'
require 'generator_spec'

require 'fog'
require 'storage/fog_helper'

unless ENV['REMOTE'] == 'true'
  Fog.mock!
end

require 'fog_credentials' # after Fog.mock!

I18n.enforce_available_locales = false

CARRIERWAVE_DIRECTORY = "carrierwave#{Time.now.to_i}" unless defined?(CARRIERWAVE_DIRECTORY)

alias :running :lambda

def file_path( *paths )
  File.expand_path(File.join(File.dirname(__FILE__), 'fixtures', *paths))
end

def public_path( *paths )
  File.expand_path(File.join(File.dirname(__FILE__), 'public', *paths))
end

CarrierWave.root = public_path
I18n.load_path << File.expand_path(File.join(File.dirname(__FILE__), "..", "lib", "carrierwave", "locale", 'en.yml'))

module CarrierWave
  module Test
    module MockStorage
      def mock_storage(kind)
        storage = mock("storage for #{kind} uploader")
        storage.stub!(:setup!)
        storage
      end
    end

    module MockFiles
      def stub_merb_tempfile(filename)
        raise "#{path} file does not exist" unless File.exist?(file_path(filename))

        t = Tempfile.new(filename)
        FileUtils.copy_file(file_path(filename), t.path)

        return t
      end

      def stub_tempfile(filename, mime_type=nil, fake_name=nil)
        raise "#{path} file does not exist" unless File.exist?(file_path(filename))

        t = Tempfile.new(filename)
        FileUtils.copy_file(file_path(filename), t.path)

        # This is stupid, but for some reason rspec won't play nice...
        eval <<-EOF
        def t.original_filename; '#{fake_name || filename}'; end
        def t.content_type; '#{mime_type}'; end
        def t.local_path; path; end
        EOF

        return t
      end

      def stub_stringio(filename, mime_type=nil, fake_name=nil)
        if filename
          t = StringIO.new( IO.read( file_path( filename ) ) )
        else
          t = StringIO.new
        end
        t.stub!(:local_path => "",
                :original_filename => filename || fake_name,
                :content_type => mime_type)
        return t
      end

      def stub_file(filename, mime_type=nil, fake_name=nil)
        f = File.open(file_path(filename))
        f.stub(:content_type) { mime_type } if mime_type
        return f
      end
    end

    module I18nHelpers
      def change_locale_and_store_translations(locale, translations, &block)
        current_locale = I18n.locale
        begin
          I18n.backend.store_translations locale, translations
          I18n.locale = locale
          yield
        ensure
          I18n.reload!
          I18n.locale = current_locale
        end
      end
    end

    module ManipulationHelpers
      def color_of_pixel(path, x, y)
        image = ::MiniMagick::Image.open(path)
        color = image.run_command("convert", "#{image.path}[1x1+#{x}+#{y}]", "-depth", "8", "txt:").split("\n")[1]
      end
    end
  end
end

RSpec.configure do |config|
  config.include CarrierWave::Test::Matchers
  config.include CarrierWave::Test::MockFiles
  config.include CarrierWave::Test::MockStorage
  config.include CarrierWave::Test::I18nHelpers
  config.include CarrierWave::Test::ManipulationHelpers
end
