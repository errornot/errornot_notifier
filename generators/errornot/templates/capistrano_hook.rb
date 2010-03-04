
Dir[File.join(File.dirname(__FILE__), '..', 'vendor', 'gems', 'errornot_notifier-*')].each do |vendored_notifier|
  $: << File.join(vendored_notifier, 'lib')
end

require 'errornot_notifier/capistrano'
