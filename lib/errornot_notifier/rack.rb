module ErrornotNotifier
  # Middleware for Rack applications. Any errors raised by the upstream
  # application will be delivered to Errornot and re-raised.
  #
  # Synopsis:
  #
  #   require 'rack'
  #   require 'errornot_notifier'
  #
  #   ErrornotNotifier.configure do |config|
  #     config.api_key = 'my_api_key'
  #   end
  #
  #   app = Rack::Builder.app do
  #     use ErrornotNotifier::Rack
  #     run lambda { |env| raise "Rack down" }
  #   end
  #
  # Use a standard ErrornotNotifier.configure call to configure your api key.
  class Rack
    def initialize(app)
      @app = app
    end

    def call(env)
      begin
        response = @app.call(env)
      rescue Exception => raised
        ErrornotNotifier.notify_or_ignore(raised, :rack_env => env)
        raise
      end

      if env['rack.exception']
        ErrornotNotifier.notify_or_ignore(env['rack.exception'], :rack_env => env)
      end

      response
    end
  end
end
