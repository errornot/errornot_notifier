# Defines deploy:notify_errornot which will send information about the deploy to Errornot.

Capistrano::Configuration.instance(:must_exist).load do
  after "deploy",            "deploy:notify_errornot"
  after "deploy:migrations", "deploy:notify_errornot"

  namespace :deploy do
    desc "Notify Errornot of the deployment"
    task :notify_errornot, :except => { :no_release => true } do
      rails_env = fetch(:errornot_env, fetch(:rails_env, "production"))
      local_user = ENV['USER'] || ENV['USERNAME']
      executable = RUBY_PLATFORM.downcase.include?('mswin') ? 'rake.bat' : 'rake'
      notify_command = "#{executable} errornot:deploy TO=#{rails_env} REVISION=#{current_revision} REPO=#{repository} USER=#{local_user}"
      notify_command << " API_KEY=#{ENV['API_KEY']}" if ENV['API_KEY']
      puts "Notifying Errornot of Deploy (#{notify_command})"
      `#{notify_command}`
      puts "Errornot Notification Complete."
    end
  end
end
