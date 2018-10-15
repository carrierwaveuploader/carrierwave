require 'spec_helper'
require 'carrierwave/storage/fog'

describe CarrierWave do
  describe '.configure' do
    before do
      CarrierWave::Uploader::Base.add_config :test_config
      CarrierWave.configure { |config| config.test_config = "foo" }
    end
    after do
      CarrierWave::Uploader::Base.singleton_class.send :undef_method, :test_config
      CarrierWave::Uploader::Base.singleton_class.send :undef_method, :test_config=
      CarrierWave::Uploader::Base.send :undef_method, :test_config
      CarrierWave::Uploader::Base.send :undef_method, :test_config=
    end

    it "proxies to Uploader configuration" do
      expect(CarrierWave::Uploader::Base.test_config).to eq('foo')
    end
  end
end

describe CarrierWave::Uploader::Base do
  let(:uploader_class) { Class.new(CarrierWave::Uploader::Base) }

  describe '.configure' do
    before do
      uploader_class.tap do |uc|
        uc.add_config :foo_bar
        uc.configure { |config| config.foo_bar = "monkey" }
      end
    end
    after do
      uploader_class.singleton_class.send :undef_method, :foo_bar
      uploader_class.singleton_class.send :undef_method, :foo_bar=
      uploader_class.send :undef_method, :foo_bar
      uploader_class.send :undef_method, :foo_bar=
    end

    it "sets a configuration parameter" do
      expect(uploader_class.foo_bar).to eq('monkey')
    end
  end

  describe ".storage" do
    let(:storage) { double('some kind of storage').as_null_object }

    it "sets the storage if an argument is given" do
      uploader_class.storage(storage)

      expect(uploader_class.storage).to storage
    end

    it "defaults to file" do
      expect(uploader_class.storage).to eq(CarrierWave::Storage::File)
    end

    it "sets the storage from the configured shortcuts if a symbol is given" do
      uploader_class.storage :file
      expect(uploader_class.storage).to eq(CarrierWave::Storage::File)
    end

    context "when inherited" do
      before { uploader_class.storage(:fog) }
      let(:subclass) { Class.new(uploader_class) }

      it "remembers the storage" do
        expect(subclass.storage).to eq(CarrierWave::Storage::Fog)
      end

      it "'s changeable" do
        expect(subclass.storage).to eq(CarrierWave::Storage::Fog)

        subclass.storage(:file)
        expect(subclass.storage).to eq(CarrierWave::Storage::File)
      end
    end

    it "raises UnknownStorageError when set unknown storage" do
      expect{ uploader_class.storage :unknown }.to raise_error(CarrierWave::UnknownStorageError, "Unknown storage: unknown")
    end
  end

  describe '.add_config' do
    before do
      uploader_class.add_config :foo_bar
      uploader_class.foo_bar = 'foo'
    end
    after do
      uploader_class.singleton_class.send :undef_method, :foo_bar
      uploader_class.singleton_class.send :undef_method, :foo_bar=
      uploader_class.send :undef_method, :foo_bar
      uploader_class.send :undef_method, :foo_bar=
    end

    it "adds a class level accessor" do
      expect(uploader_class.foo_bar).to eq('foo')
    end

    it "adds an instance level accessor" do
      expect(uploader_class.new.foo_bar).to eq('foo')
    end

    it "adds a convenient in-class setter" do
      expect(uploader_class.foo_bar).to eq('foo')
    end

    ['foo', :foo, 45, ['foo', :bar]].each do |val|
      it "'s inheritable for a #{val.class}" do
        uploader_class.singleton_class.send :undef_method, :foo_bar
        uploader_class.singleton_class.send :undef_method, :foo_bar=
        uploader_class.send :undef_method, :foo_bar
        uploader_class.send :undef_method, :foo_bar=

        uploader_class.add_config :foo_bar
        child_class = Class.new(uploader_class)

        uploader_class.foo_bar = val
        expect(uploader_class.foo_bar).to eq(val)
        expect(child_class.foo_bar).to eq(val)

        child_class.foo_bar = "bar"
        expect(child_class.foo_bar).to eq("bar")

        expect(uploader_class.foo_bar).to eq(val)
      end
    end

    describe "assigning a proc to a config attribute" do
      before do
        uploader_class.tap do |uc|
          uc.add_config :hoobatz
          uc.hoobatz = this_proc
        end
      end
    after do
      uploader_class.singleton_class.send :undef_method, :hoobatz
      uploader_class.singleton_class.send :undef_method, :hoobatz=
      uploader_class.send :undef_method, :hoobatz
      uploader_class.send :undef_method, :hoobatz=
    end

      context "when the proc accepts no arguments" do
        let(:this_proc) { proc { "a return value" } }

        it "calls the proc without arguments" do
          expect(uploader_class.new.hoobatz).to eq("a return value")
        end
      end

      context "when the proc accepts one argument" do
        let(:this_proc) { proc { |arg1| expect(arg1).to be_an_instance_of(uploader_class) } }

        it "calls the proc with an instance of the uploader" do
          uploader_class.new.hoobatz
        end
      end
    end
  end
end
