# encoding: utf-8

Given /^a datamapper class that has a '([^\']*)' column$/ do |column|
  @mountee_klass = Class.new do
    include DataMapper::Resource

    storage_names[:default] = 'users'

    property :id, DataMapper::Types::Serial
    property column.to_sym, String
  end
  @mountee_klass.auto_migrate!
end

Given /^an instance of the datamapper class$/ do
  @instance = @mountee_klass.new
end

When /^I save the datamapper record$/ do
  @instance.save
end

When /^I reload the datamapper record$/ do
  @instance = @instance.class.first(:id => @instance.key)
end

When /^I delete the datamapper record$/ do
  @instance.destroy
end
