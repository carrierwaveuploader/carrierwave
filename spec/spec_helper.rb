require 'rubygems'
require 'bundler/setup'

if RUBY_ENGINE == 'jruby'
  # Workaround for JRuby CI failure https://github.com/jruby/jruby/issues/6547#issuecomment-774104996
  require 'i18n/backend'
  require 'i18n/backend/simple'
end

require 'pry' unless ENV['GITHUB_ACTIONS']
require 'tempfile'
require 'time'
require 'logger'
require 'csv'

require 'carrierwave'
require 'timecop'
require 'open-uri'
require "webmock/rspec"
require 'mini_magick'
require "vips"
require 'active_support/core_ext'
require 'rspec/retry'

I18n.enforce_available_locales = false

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
        f
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

      def change_and_enforce_available_locales(locale, available_locales, &block)
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
        convert = ::MiniMagick::Tool.new('convert')
        convert << path
        convert.crop("1x1+#{x}+#{y}")
        convert.depth(8)
        convert << "txt:"
        convert.call.split("\n")[1]
      end
    end

    module SsrfProtectionAwareWebMock
      class Matcher
        def initialize(uri)
          @uri = uri
        end

        def call(target_uri)
          Resolv.getaddresses(@uri.hostname).any? do |address|
            candidate = @uri.dup
            candidate.hostname = address
            target_uri == WebMock::Util::URI.normalize_uri(candidate)
          end
        end

        def inspect
          "#<#{self.class.name}: #{@uri}>"
        end
      end

      def stub_request(method, uri)
        uri = URI.parse(uri) if uri.is_a?(String)
        if uri.is_a?(URI) && Gem::Version.new(SsrfFilter::VERSION) < Gem::Version.new('1.2.0')
          super method, Matcher.new(uri)
        else
          super
        end
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
  config.verbose_retry = true
  config.display_try_failure_messages = true
  config.raise_errors_for_deprecations!
  config.around :each, :with_retry do |example|
    example.run_with_retry retry: 2
  end
  config.retry_callback = proc do |example|
    sleep 1
  end
  if RUBY_ENGINE == 'jruby'
    config.filter_run_excluding :rmagick => true
  end
end
