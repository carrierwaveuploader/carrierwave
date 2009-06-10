Feature: uploader with file storage
  In order to be able to temporarily store files to disk
  As a developer using CarrierWave
  I want to cache files
  
  Scenario: cache a file
    Given an uploader class that uses the 'file' storage
    And an instance of that class
    When I cache the file 'fixtures/bork.txt'
    Then there should be a file called 'bork.txt' somewhere in a subdirectory of 'public/uploads/tmp'
    And the file called 'bork.txt' in a subdirectory of 'public/uploads/tmp' should be identical to the file at 'fixtures/bork.txt'
  
  Scenario: cache two files in succession
    Given an uploader class that uses the 'file' storage
    And an instance of that class
    When I cache the file 'fixtures/bork.txt'
    Then there should be a file called 'bork.txt' somewhere in a subdirectory of 'public/uploads/tmp'
    And the file called 'bork.txt' in a subdirectory of 'public/uploads/tmp' should be identical to the file at 'fixtures/bork.txt'
    When I cache the file 'fixtures/monkey.txt'
    Then there should be a file called 'monkey.txt' somewhere in a subdirectory of 'public/uploads/tmp'
    And the file called 'monkey.txt' in a subdirectory of 'public/uploads/tmp' should be identical to the file at 'fixtures/monkey.txt'
  
  Scenario: retrieving a file from cache
    Given an uploader class that uses the 'file' storage
    And an instance of that class
    And the file 'fixtures/bork.txt' is cached file at 'public/uploads/tmp/20090212-2343-8336-0348/bork.txt'
    When I retrieve the cache name '20090212-2343-8336-0348/bork.txt' from the cache
    Then the uploader should have 'public/uploads/tmp/20090212-2343-8336-0348/bork.txt' as its current path