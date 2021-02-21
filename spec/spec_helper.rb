require 'rubygems'
require 'bundler/setup'

if RUBY_ENGINE == 'jruby'
  # Workaround for JRuby CI failure https://github.com/jruby/jruby/issues/6547#issuecomment-774104996
  require 'i18n/backend'
  require 'i18n/backend/simple'
end

require 'pry'
require 'tempfile'
require 'time'
require 'logger'

require 'carrierwave'
require 'timecop'
require 'open-uri'
require "webmock/rspec"
require 'mini_magick'
require 'active_support/core_ext'

I18n.enforce_available_locales = false

CARRIERWAVE_DIRECTORY = "carrierwave#{Time.now.to_i}" unless defined?(CARRIERWAVE_DIRECTORY)

alias :running :lambda

def file_path( *paths )
  File.expand_path(File.join(File.dirname(__FILE__), 'fixtures', *paths))
end

def public_path( *paths )
  File.expand_path(File.join(File.dirname(__FILE__), 'public', *paths))
end

def tmp_path( *paths )
  File.expand_path(File.join(File.dirname(__FILE__), 'tmp', *paths))
end

CarrierWave.root = public_path
I18n.load_path << File.expand_path(File.join(File.dirname(__FILE__), "..", "lib", "carrierwave", "locale", 'en.yml'))

module CarrierWave
  module Test
    module MockStorage
      def mock_storage(kind)
        storage = double("storage for #{kind} uploader")
        allow(storage).to receive(:setup!)
        storage
      end
    end

    module MockFiles
      def stub_tempfile(filename, mime_type=nil, fake_name=nil)
        raise "#{path} file does not exist" unless File.exist?(file_path(filename))

        tempfile = Tempfile.new(filename)
        FileUtils.copy_file(file_path(filename), tempfile.path)
        allow(tempfile).to receive_messages(:original_filename => fake_name || filename,
                      :content_type => mime_type)
        tempfile
      end

      alias_method :stub_merb_tempfile, :stub_tempfile

      def stub_stringio(filename, mime_type=nil, fake_name=nil)
        file = IO.read( file_path( filename ) ) if filename
        stringio = StringIO.new(file)
        allow(stringio).to receive_messages(:local_path => "",
                      :original_filename => filename || fake_name,
                      :content_type => mime_type)
        stringio
      end

      def stub_file(filename, mime_type=nil, fake_name=nil)
        f = File.open(file_path(filename))
        allow(f).to receive(:content_type) { mime_type } if mime_type
        return f
      end
    end

    module I18nHelpers
      def change_locale_and_store_translations(locale, translations, &block)
        current_locale = I18n.locale
        begin
          # I18n.available_locales needs to be cleared before storing translations:
          #   https://github.com/svenfuchs/i18n/pull/391
          I18n.available_locales = nil
          I18n.backend.store_translations locale, translations
          I18n.locale = locale
          yield
        ensure
          I18n.reload!
          I18n.locale = current_locale
        end
      end

      def change_and_enforece_available_locales(locale, available_locales, &block)
        current_available_locales = I18n.available_locales
        current_enforce_available_locales_value = I18n.enforce_available_locales
        current_locale = I18n.locale
        begin
          I18n.available_locales = [:nl]
          I18n.enforce_available_locales = true
          I18n.locale = :nl
          yield
        ensure
          I18n.available_locales = current_available_locales
          I18n.enforce_available_locales = current_enforce_available_locales_value
          I18n.locale = current_locale
        end
      end
    end

    module ManipulationHelpers
      def color_of_pixel(path, x, y)
        image = ::MiniMagick::Image.open(path)
        image.run_command("convert", "#{image.path}[1x1+#{x}+#{y}]", "-depth", "8", "txt:").split("\n")[1]
      end
    end

    module SsrfProtectionAwareWebMock
      def stub_request(method, uri)
        uri = URI.parse(uri) if uri.is_a?(String)
        uri.hostname = Resolv.getaddress(uri.hostname) if uri.is_a?(URI)
        super
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
  config.prepend CarrierWave::Test::SsrfProtectionAwareWebMock
  if RUBY_ENGINE == 'jruby'
    config.filter_run_excluding :rmagick => true
  end
end
