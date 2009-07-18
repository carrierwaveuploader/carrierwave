# encoding: utf-8

Given /^an activerecord class that uses the '([^\']*)' table$/ do |name|
  @mountee_klass = Class.new(ActiveRecord::Base)
  @mountee_klass.table_name = name
end

Given /^an instance of the activerecord class$/ do
  @instance = @mountee_klass.new
end

When /^I save the active record$/ do
  @instance.save!
end

When /^I reload the active record$/ do
  @instance = @instance.class.find(@instance.id)
end

When /^I delete the active record$/ do
  @instance.destroy
end