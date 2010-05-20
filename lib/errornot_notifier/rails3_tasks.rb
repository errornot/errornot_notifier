require 'errornot_notifier'

namespace :errornot do
  desc "Notify Errornot of a new deploy."
  task :deploy => :environment do
    raise NotImplemented.new
  end

  task :log_stdout do
    require 'logger'
    RAILS_DEFAULT_LOGGER = Logger.new(STDOUT)
  end

  desc "Verify your gem installation by sending a test exception to errornot"
  task :test => ['errornot:log_stdout', :environment] do
    # require 'ruby-debug'
    # debugger

    puts "running rake errornot:test task"

    RAILS_DEFAULT_LOGGER.level = Logger::DEBUG

    require 'app/controllers/application_controller'

    class ErrornotTestingException < RuntimeError; end

    unless ErrornotNotifier.configuration.api_key
      puts "Errornot needs an API key configured! Check the README to see how to add it."
      exit
    end

    ErrornotNotifier.configuration.development_environments = []

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

      # def rescue_action(exception)
      #   rescue_action_in_public exception
      # end

      # Ensure we actually have an action to go to.
      def verify; end

      # def consider_all_requests_local
      #   false
      # end

      # def local_request?
      #   false
      # end

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

    RailsRoot::Application.routes.draw do |map|
      match 'verify' => 'application#verify', :as => 'verify'
    end


    puts 'Processing request.'
    env = Rack::MockRequest.env_for("/verify")
    response = RailsRoot::Application.call(env)

    p response

  end
end

