$TESTING=true
$:.push File.join(File.dirname(__FILE__), '..', 'lib')

require 'rubygems'

if ENV["AS"]
  puts "--> using ActiveSupport"
  require 'activesupport'
else
  puts "--> using Extlib"
  require 'extlib'
end

require 'tempfile'
require 'ruby-debug'
require 'spec'

require 'stapler'

alias :running :lambda

def file_path( *paths )
  File.expand_path(File.join(File.dirname(__FILE__), 'fixtures', *paths))
end

def public_path( *paths )
  File.expand_path(File.join(File.dirname(__FILE__), 'public', *paths))
end

Stapler.config[:public] = public_path
Stapler.config[:root] = File.expand_path(File.dirname(__FILE__))
Stapler.config[:store_dir] = 'public/uploads'
Stapler.config[:cache_dir] = 'public/uploads/tmp'

module SanitizedFileSpecHelper
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
  
  class BeIdenticalTo
    def initialize(expected)
      @expected = expected
    end
    def matches?(actual)
      @actual = actual
      FileUtils.identical?(@actual, @expected)
    end
    def failure_message
      "expected #{@actual.inspect} to be identical to #{@expected.inspect}"
    end
    def negative_failure_message
      "expected #{@actual.inspect} to not be identical to #{@expected.inspect}"
    end
  end

  def be_identical_to(expected)
    BeIdenticalTo.new(expected)
  end

  class HavePermissions
    def initialize(expected)
      @expected = expected
    end

    def matches?(actual)
      @actual = actual
      # Satisfy expectation here. Return false or raise an error if it's not met.
      (File.stat(@actual.path).mode & 0777) == @expected
    end

    def failure_message
      "expected #{@actual.inspect} to have permissions #{@expected.to_s(8)}, but they were #{(File.stat(@actual.path).mode & 0777).to_s(8)}"
    end

    def negative_failure_message
      "expected #{@actual.inspect} not to have permissions #{@expected.to_s(8)}, but it did"
    end
  end

  def have_permissions(expected)
    HavePermissions.new(expected)
  end
  
end