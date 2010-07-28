Feature: Install the Gem in a Rails application

  Background:
    Given I have built and installed the "errornot_notifier" gem

  Scenario: Use the gem without vendoring the gem in a Rails application
    When I generate a new Rails application
    And I configure the Errornot shim
    And I configure my application to require the "errornot_notifier" gem
    And I run the errornot generator with "-k myapikey --server=shingara.fr"
    Then the command should have run successfully
    And I should receive a Errornot notification
    And I should see the Rails version

  Scenario: vendor the gem and uninstall
    When I generate a new Rails application
    And I configure the Errornot shim
    And I configure my application to require the "errornot_notifier" gem
    And I unpack the "errornot_notifier" gem
    And I run the errornot generator with "-k myapikey --server=shingara.fr"
    Then the command should have run successfully
    When I uninstall the "errornot_notifier" gem
    And I install cached gems
    And I run "rake errornot:test"
    Then the command should have run successfully
    And I should receive two Errornot notifications

  Scenario: Configure the notifier by hand
    When I generate a new Rails application
    And I configure the Errornot shim
    And I configure the notifier to use "myapikey" as an API key and "shingara.fr" as host
    And I configure my application to require the "errornot_notifier" gem
    And I run the errornot generator with ""
    Then I should receive a Errornot notification

  Scenario: Try to install without an api key
    When I generate a new Rails application
    And I configure my application to require the "errornot_notifier" gem
    And I run the errornot generator with ""
    Then I should see "Must pass --api-key or create config/initializers/errornot.rb"

  Scenario: Configure and deploy using only installed gem
    When I generate a new Rails application
    And I run "capify ."
    And I configure the Errornot shim
    And I configure my application to require the "errornot_notifier" gem
    And I run the errornot generator with "-k myapikey --server=shingara.fr"
    And I run "cap -T"
    Then I should see "deploy:notify_errornot"

  Scenario: Configure and deploy using only vendored gem
    When I generate a new Rails application
    And I run "capify ."
    And I configure the Errornot shim
    And I configure my application to require the "errornot_notifier" gem
    And I unpack the "errornot_notifier" gem
    And I run the errornot generator with "-k myapikey --server=shingara.fr"
    And I uninstall the "errornot_notifier" gem
   And I install cached gems
    And I run "cap -T"
    Then I should see "deploy:notify_errornot"

  Scenario: Rescue an exception in a controller
    When I generate a new Rails application
    And I configure the Errornot shim
    And I configure my application to require the "errornot_notifier" gem
    And I run the errornot generator with "-k myapikey --server=shingara.fr"
    And I define a response for "TestController#index":
      """
      session[:value] = "test"
      raise RuntimeError, "some message"
      """
    And I route "/test/index" to "test#index"
    And I perform a request to "http://example.com:123/test/index?param=value"
    Then I should receive the following Errornot notification:
      | component     | test                                          |
      | action        | index                                         |
      | error message | RuntimeError: some message                    |
      | error class   | RuntimeError                                  |
      | session       | value: test                                   |
      | parameters    | param: value                                  |
      | url           | http://example.com:123/test/index?param=value |

  Scenario: The gem should not be considered a framework gem
    When I generate a new Rails application
    And I configure the Errornot shim
    And I configure my application to require the "errornot_notifier" gem
    And I run the errornot generator with "-k myapikey --server=shingara.fr"
    And I run "rake gems"
    Then I should see that "errornot_notifier" is not considered a framework gem

  Scenario: The app uses Vlad instead of Capistrano
    When I generate a new Rails application
    And I configure the Errornot shim
    And I configure my application to require the "errornot_notifier" gem
    And I run "touch config/deploy.rb"
    And I run "rm Capfile"
    And I run the errornot generator with "-k myapikey --server=shingara.fr"
    Then "config/deploy.rb" should not contain "capistrano"
