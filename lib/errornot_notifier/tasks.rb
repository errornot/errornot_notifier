require 'errornot_notifier'

namespace :errornot do
  desc "Notify Errornot of a new deploy."
  task :deploy => :environment do
    require 'errornot_tasks'
    ErrornotTasks.deploy(:rails_env      => ENV['TO'],
                        :scm_revision   => ENV['REVISION'],
                        :scm_repository => ENV['REPO'],
                        :local_username => ENV['USER'],
                        :api_key        => ENV['API_KEY'])
  end

  task :log_stdout do
    require 'logger'
    RAILS_DEFAULT_LOGGER = Logger.new(STDOUT)
  end

  desc "Verify your gem installation by sending a test exception to the errornot service"
  task :test => ['errornot:log_stdout', :environment] do
    RAILS_DEFAULT_LOGGER.level = Logger::DEBUG

    require 'action_controller/test_process'

    Dir["app/controllers/application*.rb"].each { |file| require(file) }

    class ErrornotTestingException < RuntimeError; end

    unless ErrornotNotifier.configuration.api_key
      puts "Errornot needs an API key configured! Check the README to see how to add it."
      exit
    end

    ErrornotNotifier.configuration.development_environments = []

    catcher = ErrornotNotifier::Rails::ActionControllerCatcher
    in_controller = ApplicationController.included_modules.include?(catcher)
    in_base = ActionController::Base.included_modules.include?(catcher)
    if !in_controller || !in_base
      puts "Rails initialization did not occur"
      exit
    end

    puts "Configuration:"
    ErrornotNotifier.configuration.to_hash.each do |key, value|
      puts sprintf("%25s: %s", key.to_s, value.inspect.slice(0, 55))
    end

    unless defined?(ApplicationController)
      puts "No ApplicationController found"
      exit
    end

    puts 'Setting up the Controller.'
    class ApplicationController
      # This is to bypass any filters that may prevent access to the action.
      prepend_before_filter :test_errornot
      def test_errornot
        puts "Raising '#{exception_class.name}' to simulate application failure."
        raise exception_class.new, 'Testing errornot via "rake errornot:test". If you can see this, it works.'
      end

      def rescue_action(exception)
        rescue_action_in_public exception
      end

      # Ensure we actually have an action to go to.
      def verify; end

      def consider_all_requests_local
        false
      end

      def local_request?
        false
      end

      def exception_class
        exception_name = ENV['EXCEPTION'] || "ErrornotTestingException"
        Object.const_get(exception_name)
      rescue
        Object.const_set(exception_name, Class.new(Exception))
      end

      def logger
        nil
      end
    end
    class ErrornotVerificationController < ApplicationController; end

    puts 'Processing request.'
    request = ActionController::TestRequest.new
    response = ActionController::TestResponse.new
    ErrornotVerificationController.new.process(request, response)
  end
end

