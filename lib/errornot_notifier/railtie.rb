require 'errornot_notifier'
require 'rails'

module ErrornotNotifier
  class Railtie < Rails::Railtie
    railtie_name :errornot_notifier

    rake_tasks do
      require "errornot_notifier/rails3_tasks"
    end
  end
end
