Feature: uploader with file storage and a processor that reverses the file
  In order to be awesome
  As a developer using CarrierWave
  I want to upload files to the filesystem

  Background:
    Given an uploader class that uses the 'file' storage
    And an instance of that class
    And the class has a method called 'reverse' that reverses the contents of a file
    And the class will process 'reverse'

  Scenario: store a file
    When I store the file 'fixtures/bork.txt'
    Then there should be a file at 'public/uploads/bork.txt'
    And the file at 'public/uploads/bork.txt' should not be identical to the file at 'fixtures/bork.txt'
    And the file at 'public/uploads/bork.txt' should be the reverse of the file at 'fixtures/bork.txt'

  Scenario: store two files in succession
    When I store the file 'fixtures/bork.txt'
    Then there should be a file at 'public/uploads/bork.txt'
    And the file at 'public/uploads/bork.txt' should not be identical to the file at 'fixtures/bork.txt'
    And the file at 'public/uploads/bork.txt' should be the reverse of the file at 'fixtures/bork.txt'
    When I store the file 'fixtures/monkey.txt'
    Then there should be a file at 'public/uploads/monkey.txt'
    And the file at 'public/uploads/monkey.txt' should not be identical to the file at 'fixtures/monkey.txt'
    And the file at 'public/uploads/monkey.txt' should be the reverse of the file at 'fixtures/monkey.txt'

  Scenario: cache a file and then store it
    When I cache the file 'fixtures/bork.txt'
    Then there should be a file called 'bork.txt' somewhere in a subdirectory of 'public/uploads/tmp'
    And the file called 'bork.txt' in a subdirectory of 'public/uploads/tmp' should not be identical to the file at 'fixtures/bork.txt'
    And there should not be a file at 'public/uploads/bork.txt'
    When I store the file
    Then there should be a file at 'public/uploads/bork.txt'
    And the file at 'public/uploads/bork.txt' should not be identical to the file at 'fixtures/bork.txt'
    And the file at 'public/uploads/bork.txt' should be the reverse of the file at 'fixtures/bork.txt'

  Scenario: retrieving a file from cache then storing
    Given the file 'fixtures/bork.txt' is cached file at 'public/uploads/tmp/1369894322-345-2255/bork.txt'
    When I retrieve the cache name '1369894322-345-2255/bork.txt' from the cache
    And I store the file
    Then there should be a file at 'public/uploads/bork.txt'
    And the file at 'public/uploads/bork.txt' should be identical to the file at 'fixtures/bork.txt'
