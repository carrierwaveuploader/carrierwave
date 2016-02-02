Feature: uploader with file storage and versions
  In order to be awesome
  As a developer using CarrierWave
  I want to upload files to the filesystem

  Background:
    Given an uploader class that uses the 'file' storage
    And that the uploader class has a version named 'thumb'
    And an instance of that class

  Scenario: store a file
    When I store the file 'fixtures/bork.txt'
    Then there should be a file at 'public/uploads/bork.txt'
    Then there should be a file at 'public/uploads/thumb_bork.txt'
    And the file at 'public/uploads/bork.txt' should be identical to the file at 'fixtures/bork.txt'
    And the file at 'public/uploads/thumb_bork.txt' should be identical to the file at 'fixtures/bork.txt'
    And the uploader should have the url '/uploads/bork.txt'
    And the uploader's version 'thumb' should have the url '/uploads/thumb_bork.txt'

  Scenario: cache a file and then store it
    When I cache the file 'fixtures/bork.txt'
    Then there should be a file called 'bork.txt' somewhere in a subdirectory of 'public/uploads/tmp'
    Then there should be a file called 'thumb_bork.txt' somewhere in a subdirectory of 'public/uploads/tmp'
    And the file called 'bork.txt' in a subdirectory of 'public/uploads/tmp' should be identical to the file at 'fixtures/bork.txt'
    And there should not be a file at 'public/uploads/bork.txt'
    And there should not be a file at 'public/uploads/thumb_bork.txt'
    When I store the file
    Then there should be a file at 'public/uploads/bork.txt'
    And there should be a file at 'public/uploads/thumb_bork.txt'
    And the file at 'public/uploads/bork.txt' should be identical to the file at 'fixtures/bork.txt'
    And the file at 'public/uploads/thumb_bork.txt' should be identical to the file at 'fixtures/bork.txt'
    And the uploader should have the url '/uploads/bork.txt'
    And the uploader's version 'thumb' should have the url '/uploads/thumb_bork.txt'

  Scenario: retrieving a file from cache then storing
    Given the file 'fixtures/bork.txt' is cached file at 'public/uploads/tmp/1369894322-345-1234-2255/bork.txt'
    Given the file 'fixtures/monkey.txt' is cached file at 'public/uploads/tmp/1369894322-345-1234-2255/thumb_bork.txt'
    When I retrieve the cache name '1369894322-345-1234-2255/bork.txt' from the cache
    And I store the file
    Then there should be a file at 'public/uploads/bork.txt'
    Then there should be a file at 'public/uploads/thumb_bork.txt'
    And the file at 'public/uploads/bork.txt' should be identical to the file at 'fixtures/bork.txt'
    And the file at 'public/uploads/thumb_bork.txt' should be identical to the file at 'fixtures/monkey.txt'

  Scenario: retrieving a file from store
    Given the file 'fixtures/bork.txt' is stored at 'public/uploads/bork.txt'
    Given the file 'fixtures/monkey.txt' is stored at 'public/uploads/thumb_bork.txt'
    When I retrieve the file 'bork.txt' from the store
    Then the uploader should have the url '/uploads/bork.txt'
    And the uploader's version 'thumb' should have the url '/uploads/thumb_bork.txt'
