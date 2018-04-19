Feature: downloading files
  In order to allow users to upload remote files
  As a developer using CarrierWave
  I want to download files to the filesystem via HTTP

  Background:
    Given an uploader class that uses the 'file' storage
    And an instance of that class

  Scenario: download a file
    When I download the file 'http://s3.amazonaws.com/Monkey/testfile.txt'
    Then there should be a file called 'testfile.txt' somewhere in a subdirectory of 'public/uploads/tmp'
    And the file called 'testfile.txt' in a subdirectory of 'public/uploads/tmp' should contain 'S3 Remote File'

  Scenario: downloading a file then storing
    When I download the file 'http://s3.amazonaws.com/Monkey/testfile.txt'
    And I store the file
    Then there should be a file at 'public/uploads/testfile.txt'
    And the file at 'public/uploads/testfile.txt' should contain 'S3 Remote File'

