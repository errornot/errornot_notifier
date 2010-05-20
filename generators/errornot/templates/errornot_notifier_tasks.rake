# Don't load anything when running the gems:* tasks.
# Otherwise, errornot_notifier will be considered a framework gem.
# https://thoughtbot.lighthouseapp.com/projects/14221/tickets/629
unless ARGV.any? {|a| a =~ /^gems/}
  Dir[File.join(RAILS_ROOT, 'vendor', 'gems', 'errornot_notifier-*')].each do |vendored_notifier|
    $: << File.join(vendored_notifier, 'lib')
  end

  begin
    require 'errornot_notifier/tasks'
  rescue LoadError => exception
    namespace :errornot do
      %w(test log_stdout).each do |task_name|
        desc "Missing dependency for errornot:#{task_name}"
        task task_name do
          $stderr.puts "Failed to run errornot:#{task_name} because of missing dependency."
          $stderr.puts "You probably need to run `rake gems:install` to install the errornot_notifier gem"
          abort exception.inspect
        end
      end
    end
  end
end
