# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{errornot_notifier}
  s.version = "1.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["thoughtbot, inc, Cyril Mougel"]
  s.date = %q{2010-09-08}
  s.email = %q{cyril.mougel@gmail.com}
  s.extra_rdoc_files = ["README.rdoc"]
  s.files = ["CHANGELOG", "INSTALL", "MIT-LICENSE", "Rakefile", "README.rdoc", "SUPPORTED_RAILS_VERSIONS", "TESTING.rdoc", "generators/errornot/errornot_generator.rb", "generators/errornot/lib/insert_commands.rb", "generators/errornot/lib/rake_commands.rb", "generators/errornot/templates/capistrano_hook.rb", "generators/errornot/templates/errornot_notifier_tasks.rake", "generators/errornot/templates/initializer.rb", "lib/errornot_notifier/backtrace.rb", "lib/errornot_notifier/capistrano.rb", "lib/errornot_notifier/configuration.rb", "lib/errornot_notifier/notice.rb", "lib/errornot_notifier/rack.rb", "lib/errornot_notifier/rails/action_controller_catcher.rb", "lib/errornot_notifier/rails/controller_methods.rb", "lib/errornot_notifier/rails/error_lookup.rb", "lib/errornot_notifier/rails/javascript_notifier.rb", "lib/errornot_notifier/rails.rb", "lib/errornot_notifier/rails3_tasks.rb", "lib/errornot_notifier/railtie.rb", "lib/errornot_notifier/sender.rb", "lib/errornot_notifier/tasks.rb", "lib/errornot_notifier/version.rb", "lib/errornot_notifier.rb", "lib/errornot_tasks.rb", "lib/rails/generators/errornot/errornot_generator.rb", "test/backtrace_test.rb", "test/catcher_test.rb", "test/configuration_test.rb", "test/erronot_tasks_test.rb", "test/errornot_tasks_test.rb", "test/helper.rb", "test/logger_test.rb", "test/notice_test.rb", "test/notifier_test.rb", "test/rack_test.rb", "test/rails_initializer_test.rb", "test/sender_test.rb", "rails/init.rb", "script/integration_test.rb", "lib/templates/javascript_notifier.erb", "lib/templates/rescue.erb"]
  s.homepage = %q{http://github.com/shingara/errornot_notifier}
  s.rdoc_options = ["--line-numbers", "--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Send your application errors to a hosted service and reclaim your inbox.}
  s.test_files = ["test/backtrace_test.rb", "test/catcher_test.rb", "test/configuration_test.rb", "test/erronot_tasks_test.rb", "test/errornot_tasks_test.rb", "test/logger_test.rb", "test/notice_test.rb", "test/notifier_test.rb", "test/rack_test.rb", "test/rails_initializer_test.rb", "test/sender_test.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activesupport>, [">= 0"])
      s.add_development_dependency(%q<activerecord>, [">= 0"])
      s.add_development_dependency(%q<actionpack>, [">= 0"])
      s.add_development_dependency(%q<jferris-mocha>, [">= 0"])
      s.add_development_dependency(%q<nokogiri>, [">= 0"])
      s.add_development_dependency(%q<shoulda>, [">= 0"])
    else
      s.add_dependency(%q<activesupport>, [">= 0"])
      s.add_dependency(%q<activerecord>, [">= 0"])
      s.add_dependency(%q<actionpack>, [">= 0"])
      s.add_dependency(%q<jferris-mocha>, [">= 0"])
      s.add_dependency(%q<nokogiri>, [">= 0"])
      s.add_dependency(%q<shoulda>, [">= 0"])
    end
  else
    s.add_dependency(%q<activesupport>, [">= 0"])
    s.add_dependency(%q<activerecord>, [">= 0"])
    s.add_dependency(%q<actionpack>, [">= 0"])
    s.add_dependency(%q<jferris-mocha>, [">= 0"])
    s.add_dependency(%q<nokogiri>, [">= 0"])
    s.add_dependency(%q<shoulda>, [">= 0"])
  end
end
