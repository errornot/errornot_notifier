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
    Then I should see "** [ErrorNot Logger] Success: Net::HTTPOK"
    And I should receive two Errornot notifications

  Scenario: Configure the notifier by hand
    When I generate a new Rails application
    And I configure the Errornot shim
    And I configure the notifier to use "myapikey" as an API key and "shingara.fr" as host
    And I configure my application to require the "errornot_notifier" gem
    And I run the errornot generator with ""
    Then I should receive a Errornot notification

  Scenario: Configuration within initializer isn't overridden by Railtie
    When I generate a new Rails application
    And I configure the Errornot shim
    And I configure my application to require the "errornot_notifier" gem
    And I run the errornot generator with "-k myapikey --server=shingara.fr"
    Then the command should have run successfully
    When I configure the notifier to use the following configuration lines:
      """
      config.api_key = "myapikey"
      config.host = 'shingara.fr'
      config.project_root = "argle/bargle"
      """
    And I define a response for "TestController#index":
      """
      session[:value] = "test"
      raise RuntimeError, "some message"
      """
    And I route "/test/index" to "test#index"
    And I perform a request to "http://example.com:123/test/index?param=value"
    Then I should receive the following Errornot notification:
      | error message | RuntimeError: some message |

  Scenario: Try to install without an api key
    When I generate a new Rails application
    And I configure my application to require the "errornot_notifier" gem
    And I run the errornot generator with ""
    Then I should see "Must pass --api-key or --heroku or create config/initializers/errornot.rb"

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

  Scenario: Support the Heroku addon in the generator
    When I generate a new Rails application
    And I configure the Errornot shim
    And I configure the Heroku rake shim
    And I configure my application to require the "errornot_notifier" gem
    And I set the environment variable "HOPTOAD_API_KEY" to "myapikey"
    And I run the errornot generator with "--heroku --server=shingara.fr"
    Then the command should have run successfully
    And I should receive a Errornot notification
    And I should see the Rails version
    And my Errornot configuration should contain the following line:
      """
      config.api_key = ENV['HOPTOAD_API_KEY']
      config.host = 'shingara.fr'
      """

  Scenario: Filtering parameters in a controller
    When I generate a new Rails application
    And I configure the Errornot shim
    And I configure my application to require the "errornot_notifier" gem
    And I run the errornot generator with "-k myapikey --server=shingara.fr"
    When I configure the notifier to use the following configuration lines:
      """
      config.api_key = "myapikey"
      config.host = 'shingara.fr'
      config.params_filters << "credit_card_number"
      """
    And I define a response for "TestController#index":
      """
      params[:credit_card_number] = "red23"
      raise RuntimeError, "some message"
      """
    And I route "/test/index" to "test#index"
    And I perform a request to "http://example.com:123/test/index?param=value"
    Then I should receive the following Errornot notification:
      | component     | test                                          |
      | action        | index                                         |
      | error message | RuntimeError: some message                    |
      | error class   | RuntimeError                                  |
      | parameters    | credit_card_number: [FILTERED]                |
      | url           | http://example.com:123/test/index?param=value |

  Scenario: Filtering session in a controller
    When I generate a new Rails application
    And I configure the Errornot shim
    And I configure my application to require the "errornot_notifier" gem
    And I run the errornot generator with "-k myapikey --server=shingara.fr"
    When I configure the notifier to use the following configuration lines:
      """
      config.api_key = "myapikey"
      config.host = 'shingara.fr'
      config.params_filters << "secret"
      """
    And I define a response for "TestController#index":
      """
      session["secret"] = "blue42"
      raise RuntimeError, "some message"
      """
    And I route "/test/index" to "test#index"
    And I perform a request to "http://example.com:123/test/index?param=value"
    Then I should receive the following Errornot notification:
      | component     | test                                          |
      | action        | index                                         |
      | error message | RuntimeError: some message                    |
      | error class   | RuntimeError                                  |
      | session       | secret: [FILTERED]                            |
      | url           | http://example.com:123/test/index?param=value |

  Scenario: Filtering session and params based on Rails parameter filters
    When I generate a new Rails application
    And I configure the Errornot shim
    And I configure my application to require the "errornot_notifier" gem
    And I run the errornot generator with "-k myapikey --server=shingara.fr"
    And I configure the application to filter parameter "secret"
    And I define a response for "TestController#index":
      """
      params["secret"] = "red23"
      session["secret"] = "blue42"
      raise RuntimeError, "some message"
      """
    And I route "/test/index" to "test#index"
    And I perform a request to "http://example.com:123/test/index?param=value"
    Then I should receive the following Errornot notification:
      | component     | test                                          |
      | action        | index                                         |
      | error message | RuntimeError: some message                    |
      | error class   | RuntimeError                                  |
      | params        | secret: [FILTERED]                            |
      | session       | secret: [FILTERED]                            |
      | url           | http://example.com:123/test/index?param=value |
