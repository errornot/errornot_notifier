rails3 = defined?(ActiveSupport::Notifications)
require 'errornot_notifier'
require 'errornot_notifier/rails/controller_methods'
unless rails3
  require 'errornot_notifier/rails/action_controller_catcher'
end
require 'errornot_notifier/rails/error_lookup'

module ErrornotNotifier
  module Rails
    def self.initialize
      if defined?(ActiveSupport::Notifications)
        ActiveSupport::Notifications.subscribe "action_dispatch.show_exception" do |*args|
          payload = args.last

          env = payload[:env]
          exception = payload[:exception]
          request = Rack::Request.new(env)

          errornot_request_data = {
              :parameters       => request.params,
              :session_data     => env["rack.session"].to_hash,
              # :controller       => params[:controller],
              # :action           => params[:action],
              :url              => request.url,
              :cgi_data         => env
          }

          ErrornotNotifier.notify(exception, errornot_request_data)
        end
      elsif defined?(ActionController::Base)
        ActionController::Base.send(:include, ErrornotNotifier::Rails::ActionControllerCatcher)
        ActionController::Base.send(:include, ErrornotNotifier::Rails::ErrorLookup)
        ActionController::Base.send(:include, ErrornotNotifier::Rails::ControllerMethods)
      end

      rails_logger = if defined?(::Rails.logger)
                       ::Rails.logger
                     elsif defined?(RAILS_DEFAULT_LOGGER)
                       RAILS_DEFAULT_LOGGER
                     end

      rails3 = defined?(ActiveSupport::Notifications)
      unless rails3
        if defined?(::Rails.configuration) && ::Rails.configuration.respond_to?(:middleware)
          ::Rails.configuration.middleware.insert_after 'ActionController::Failsafe',
                                                        ErrornotNotifier::Rack
        end
      end

      ErrornotNotifier.configure(true) do |config|
        config.logger = rails_logger
        config.environment_name = RAILS_ENV  if defined?(RAILS_ENV)
        config.project_root     = RAILS_ROOT if defined?(RAILS_ROOT)
        config.framework        = "Rails: #{::Rails::VERSION::STRING}" if defined?(::Rails::VERSION)
      end
    end
  end
end

ErrornotNotifier::Rails.initialize

