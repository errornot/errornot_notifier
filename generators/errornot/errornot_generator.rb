require File.expand_path(File.dirname(__FILE__) + "/lib/insert_commands.rb")
require File.expand_path(File.dirname(__FILE__) + "/lib/rake_commands.rb")

class ErrornotGenerator < Rails::Generator::Base
  def add_options!(opt)
    opt.on('-k', '--api-key=key', String, "Your ErrorNot API key") {|v| options[:api_key] = v}
    opt.on('-s', '--server=host', String, "Your host with errorNot is installed") {|v| options[:host] = v}
    opt.on('-h', '--heroku',              "Use the Heroku addon to provide your Hoptoad API key") {|v| options[:heroku]  = v}
  end

  def manifest
    if !api_key_configured? && !options[:api_key] && !options[:heroku]
      puts "Must pass --api-key or --heroku or create config/initializers/errornot.rb"
      exit
    end

    if !api_key_configured? && !options[:host]
      puts "Must pass --server or create config/initializers/errornot.rb"
      exit
    end
    record do |m|
      m.directory 'lib/tasks'
      m.file 'errornot_notifier_tasks.rake', 'lib/tasks/errornot_notifier_tasks.rake'
      if ['config/deploy.rb', 'Capfile'].all? { |file| File.exists?(file) }
        m.append_to 'config/deploy.rb', capistrano_hook
      end
      if api_key_expression
        if use_initializer?
          m.template 'initializer.rb', 'config/initializers/errornot.rb',
            :assigns => {:api_key => api_key_expression,
          :host => options[:host]}
        else
          m.template 'initializer.rb', 'config/errornot.rb',
            :assigns => {:api_key => api_key_expression,
          :host => options[:host]}
          m.append_to 'config/environment.rb', "require 'config/errornot'"
        end
      end
      m.rake "errornot:test --trace", :generate_only => true
    end
  end

  def api_key_expression
    s = if options[:api_key]
          "'#{options[:api_key]}'"
        elsif options[:heroku]
          "ENV['HOPTOAD_API_KEY']"
        end
  end

  def use_initializer?
    Rails::VERSION::MAJOR > 1
  end

  def api_key_configured?
    File.exists?('config/initializers/errornot.rb') ||
      system("grep ErrornotNotifier config/environment.rb")
  end

  def capistrano_hook
    IO.read(source_path('capistrano_hook.rb'))
  end

end
