# encoding: utf-8

###
# EXISTENCE

Then /^there should be a file at '(.*?)'$/ do |file|
  File.exist?(file_path(file)).should be_truthy
end

Then /^there should not be a file at '(.*?)'$/ do |file|
  File.exist?(file_path(file)).should be_falsey
end

Then /^there should be a file called '(.*?)' somewhere in a subdirectory of '(.*?)'$/ do |file, directory|
  Dir.glob(File.join(file_path(directory), '**', file)).any?.should be_truthy
end

###
# IDENTICAL

Then /^the file at '(.*?)' should be identical to the file at '(.*?)'$/ do |one, two|
  File.read(file_path(one)).should == File.read(file_path(two))
end

Then /^the file at '(.*?)' should not be identical to the file at '(.*?)'$/ do |one, two|
  File.read(file_path(one)).should_not == File.read(file_path(two))
end

Then /^the file called '(.*?)' in a subdirectory of '(.*?)' should be identical to the file at '(.*?)'$/ do |file, directory, other|
  File.read(Dir.glob(File.join(file_path(directory), '**', file)).first).should == File.read(file_path(other))
end

Then /^the file called '(.*?)' in a subdirectory of '(.*?)' should not be identical to the file at '(.*?)'$/ do |file, directory, other|
  File.read(Dir.glob(File.join(file_path(directory), '**', file)).first).should_not == File.read(file_path(other))
end

###
# CONTENT

Then /^the file called '([^']+)' in a subdirectory of '([^']+)' should contain '([^']+)'$/ do |file, directory, content|
  File.read(Dir.glob(File.join(file_path(directory), '**', file)).first).should include(content)
end

Then /^the file at '([^']+)' should contain '([^']+)'$/ do |path, content|
  File.read(file_path(path)).should include(content)
end

###
# REVERSING

Then /^the file at '(.*?)' should be the reverse of the file at '(.*?)'$/ do |one, two|
  File.read(file_path(one)).should == File.read(file_path(two)).reverse
end
