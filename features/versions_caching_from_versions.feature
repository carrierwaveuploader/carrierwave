Feature: uploader with file storage and versions with overridden store dir
  In order to be awesome
  As a developer using CarrierWave
  I want to upload files to the filesystem

  Background:
    Given an uploader class that uses the 'file' storage
    Given a processor method named :upcase
    And that the uploader class has a version named 'thumb' which process 'upcase'
    And that the version 'thumb' has the store_dir overridden to 'public/monkey/llama'
    And that the uploader class has a version named 'small_thumb' which is based on version 'thumb'
    And that the version 'small_thumb' has the store_dir overridden to 'public/monkey/toro'
    And an instance of that class

  Scenario: cache a file and then store it
    When I cache the file 'fixtures/bork.txt'
    Then there should be a file called 'bork.txt' somewhere in a subdirectory of 'public/uploads/tmp'
    Then there should be a file called 'thumb_bork.txt' somewhere in a subdirectory of 'public/uploads/tmp'
    Then there should be a file called 'small_thumb_bork.txt' somewhere in a subdirectory of 'public/uploads/tmp'
    And the file called 'bork.txt' in a subdirectory of 'public/uploads/tmp' should be identical to the file at 'fixtures/bork.txt'
    And the file called 'thumb_bork.txt' in a subdirectory of 'public/uploads/tmp' should be identical to the file at 'fixtures/upcased_bork.txt'
    And the file called 'small_thumb_bork.txt' in a subdirectory of 'public/uploads/tmp' should be identical to the file at 'fixtures/upcased_bork.txt'
    And there should not be a file at 'public/uploads/bork.txt'
    And there should not be a file at 'public/monkey/llama/thumb_bork.txt'
    And there should not be a file at 'public/monkey/toro/small_thumb_bork.txt'
    When I store the file
    Then there should be a file at 'public/uploads/bork.txt'
    Then there should be a file at 'public/monkey/llama/thumb_bork.txt'
    Then there should be a file at 'public/monkey/toro/small_thumb_bork.txt'
    And the file at 'public/uploads/bork.txt' should be identical to the file at 'fixtures/bork.txt'
    And the file at 'public/monkey/llama/thumb_bork.txt' should be identical to the file at 'fixtures/upcased_bork.txt'
    And the file at 'public/monkey/toro/small_thumb_bork.txt' should be identical to the file at 'fixtures/upcased_bork.txt'