Feature: uploader with file storage and overriden filename
  In order to be awesome
  As a developer using CarrierWave
  I want to upload files to the filesystem with an overriden filename
  
  Background:
    Given an uploader class that uses the 'file' storage
    And that the uploader reverses the filename
    And an instance of that class 
  
  Scenario: store a file
    When I store the file 'fixtures/bork.txt'
    Then there should be a file at 'public/uploads/txt.krob'
    And the file at 'public/uploads/txt.krob' should be identical to the file at 'fixtures/bork.txt'
  
  Scenario: store two files in succession
    When I store the file 'fixtures/bork.txt'
    Then there should be a file at 'public/uploads/txt.krob'
    And the file at 'public/uploads/txt.krob' should be identical to the file at 'fixtures/bork.txt'
    When I store the file 'fixtures/monkey.txt'
    Then there should be a file at 'public/uploads/txt.yeknom'
    And the file at 'public/uploads/txt.yeknom' should be identical to the file at 'fixtures/monkey.txt'
  
  Scenario: cache a file and then store it
    When I cache the file 'fixtures/bork.txt'
    Then there should be a file called 'bork.txt' somewhere in a subdirectory of 'public/uploads/tmp'
    And the file called 'bork.txt' in a subdirectory of 'public/uploads/tmp' should be identical to the file at 'fixtures/bork.txt'
    And there should not be a file at 'public/uploads/txt.krob'
    When I store the file
    Then there should be a file at 'public/uploads/txt.krob'
    And the file at 'public/uploads/txt.krob' should be identical to the file at 'fixtures/bork.txt'
  
  Scenario: retrieving a file from cache then storing
    Given the file 'fixtures/bork.txt' is cached file at 'public/uploads/tmp/20090212-2343-8336-0348/bork.txt'
    When I retrieve the cache name '20090212-2343-8336-0348/bork.txt' from the cache
    And I store the file
    Then there should be a file at 'public/uploads/txt.krob'
    And the file at 'public/uploads/txt.krob' should be identical to the file at 'fixtures/bork.txt'
