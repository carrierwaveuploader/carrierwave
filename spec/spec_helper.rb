# encoding: utf-8

$TESTING=true
$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'rubygems'

require 'tempfile'
#require 'ruby-debug'
require 'spec'
require 'spec/autorun'

require 'carrierwave'
require 'timecop'
require 'time'
require 'json'

require 'logger'

alias :running :lambda

def file_path( *paths )
  File.expand_path(File.join(File.dirname(__FILE__), 'fixtures', *paths))
end

def public_path( *paths )
  File.expand_path(File.join(File.dirname(__FILE__), 'public', *paths))
end

CarrierWave.root = public_path

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
        t.stub!(:local_path).and_return("")
        t.stub!(:original_filename).and_return(filename || fake_name)
        t.stub!(:content_type).and_return(mime_type)
        return t
      end

      def stub_file(filename, mime_type=nil, fake_name=nil)
        f = File.open(file_path(filename))
        return f
      end
    end
  end
end

Spec::Runner.configure do |config|
  config.include CarrierWave::Test::Matchers
  config.include CarrierWave::Test::MockFiles
  config.include CarrierWave::Test::MockStorage
end
