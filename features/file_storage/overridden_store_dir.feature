Feature: uploader with file storage and overridden store dir
  In order to be awesome
  As a developer using CarrierWave
  I want to upload files to the filesystem
  
  Background:
    Given an uploader class that uses the 'file' storage
    And that the uploader has the store_dir overridden to 'public/monkey/llama'
    And an instance of that class    
  
  Scenario: store a file
    When I store the file 'fixtures/bork.txt'
    Then there should be a file at 'public/monkey/llama/bork.txt'
    And the file at 'public/monkey/llama/bork.txt' should be identical to the file at 'fixtures/bork.txt'
  
  Scenario: store two files in succession
    When I store the file 'fixtures/bork.txt'
    Then there should be a file at 'public/monkey/llama/bork.txt'
    And the file at 'public/monkey/llama/bork.txt' should be identical to the file at 'fixtures/bork.txt'
    When I store the file 'fixtures/monkey.txt'
    Then there should be a file at 'public/monkey/llama/monkey.txt'
    And the file at 'public/monkey/llama/monkey.txt' should be identical to the file at 'fixtures/monkey.txt'
  
  Scenario: cache a file and then store it
    When I cache the file 'fixtures/bork.txt'
    Then there should be a file called 'bork.txt' somewhere in a subdirectory of 'public/uploads/tmp'
    And the file called 'bork.txt' in a subdirectory of 'public/uploads/tmp' should be identical to the file at 'fixtures/bork.txt'
    And there should not be a file at 'public/monkey/llama/bork.txt'
    When I store the file
    Then there should be a file at 'public/monkey/llama/bork.txt'
    And the file at 'public/monkey/llama/bork.txt' should be identical to the file at 'fixtures/bork.txt'
  
  Scenario: retrieving a file from cache then storing
    Given the file 'fixtures/bork.txt' is cached file at 'public/uploads/tmp/20090212-2343-8336-0348/bork.txt'
    When I retrieve the cache name '20090212-2343-8336-0348/bork.txt' from the cache
    And I store the file
    Then there should be a file at 'public/monkey/llama/bork.txt'
    And the file at 'public/monkey/llama/bork.txt' should be identical to the file at 'fixtures/bork.txt'
