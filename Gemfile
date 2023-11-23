source "https://rubygems.org"

gem "rails", ">= 6.0.0"
gem "activemodel-serializers-xml"
gem 'sqlite3', platforms: :ruby
gem "activerecord-jdbcsqlite3-adapter", platform: [:jruby, :truffleruby]
# See https://github.com/fog/fog-google/issues/535 for this restriction.
gem "fog-google", "~> 1.13.0" if RUBY_VERSION.to_f < 2.7

gemspec
