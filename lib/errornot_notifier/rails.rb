require 'errornot_notifier'
require 'errornot_notifier/rails/controller_methods'
require 'errornot_notifier/rails/action_controller_catcher'
require 'errornot_notifier/rails/error_lookup'

module ErrornotNotifier
  module Rails
    def self.initialize
      if defined?(ActionController::Base)
        ActionController::Base.send(:include, ErrornotNotifier::Rails::ActionControllerCatcher)
        ActionController::Base.send(:include, ErrornotNotifier::Rails::ErrorLookup)
        ActionController::Base.send(:include, ErrornotNotifier::Rails::ControllerMethods)
      end

      rails_logger = if defined?(::Rails.logger)
                       ::Rails.logger
                     elsif defined?(RAILS_DEFAULT_LOGGER)
                       RAILS_DEFAULT_LOGGER
                     end

      if defined?(::Rails.configuration) && ::Rails.configuration.respond_to?(:middleware)
        ::Rails.configuration.middleware.insert_after 'ActionController::Failsafe',
          ErrornotNotifier::Rack
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
