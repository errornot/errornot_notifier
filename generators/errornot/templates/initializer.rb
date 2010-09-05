<% if Rails::VERSION::MAJOR < 3 && Rails::VERSION::MINOR < 2 -%>
require 'errornot_notifier/rails'
<% end -%>
ErrornotNotifier.configure do |config|
  config.api_key = <%= api_key_expression %>
  config.host = '<%= host %>'
end
