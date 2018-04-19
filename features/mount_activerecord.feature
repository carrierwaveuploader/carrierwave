Feature: Mount an Uploader on ActiveRecord class
  In order to easily attach files to a form
  As a web developer using CarrierWave
  I want to mount an uploader on an ActiveRecord class

  Background:
    Given an uploader class that uses the 'file' storage
    And an activerecord class that uses the 'users' table
    And the uploader class is mounted on the 'avatar' column
    And an instance of the activerecord class

  Scenario: assign a file
    When I assign the file 'fixtures/bork.txt' to the 'avatar' column
    Then there should be a file called 'bork.txt' somewhere in a subdirectory of 'public/uploads/tmp'
    And the file called 'bork.txt' in a subdirectory of 'public/uploads/tmp' should be identical to the file at 'fixtures/bork.txt'

  Scenario: assign a file and save the record
    When I assign the file 'fixtures/bork.txt' to the 'avatar' column
    And I save the active record
    Then there should be a file at 'public/uploads/bork.txt'
    And the file at 'public/uploads/bork.txt' should be identical to the file at 'fixtures/bork.txt'
    And the url for the column 'avatar' should be '/uploads/bork.txt'

  Scenario: assign a file and retrieve it from cache
    When I assign the file 'fixtures/bork.txt' to the 'avatar' column
    And I retrieve the file later from the cache name for the column 'avatar'
    And I save the active record
    Then there should be a file at 'public/uploads/bork.txt'
    And the file at 'public/uploads/bork.txt' should be identical to the file at 'fixtures/bork.txt'
    And the url for the column 'avatar' should be '/uploads/bork.txt'

  Scenario: store a file and retrieve it later
    When I assign the file 'fixtures/bork.txt' to the 'avatar' column
    And I retrieve the file later from the cache name for the column 'avatar'
    And I save the active record
    Then there should be a file at 'public/uploads/bork.txt'
    When I reload the active record
    Then the url for the column 'avatar' should be '/uploads/bork.txt'

  Scenario: store a file and delete the record
    When I assign the file 'fixtures/bork.txt' to the 'avatar' column
    And I retrieve the file later from the cache name for the column 'avatar'
    And I save the active record
    Then there should be a file at 'public/uploads/bork.txt'
    When I delete the active record
    Then there should not be a file at 'public/uploads/bork.txt'
