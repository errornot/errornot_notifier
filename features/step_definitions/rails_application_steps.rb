require 'uri'

When /^I generate a new Rails application$/ do
  @terminal.cd(TEMP_DIR)
  version_string = ENV['RAILS_VERSION']

  rails3 = version_string =~ /^3/

  if rails3
    rails_binary_gem = 'railties'
  else
    rails_binary_gem = 'rails'
  end

  load_rails = <<-RUBY
    gem '#{rails_binary_gem}', '#{version_string}'; \
    load Gem.bin_path('#{rails_binary_gem}', 'rails', '#{version_string}')
  RUBY

  @terminal.run(%{ruby -rubygems -e "#{load_rails.strip!}" rails_root})
  if rails_root_exists?
    @terminal.echo("Generated a Rails #{rails_version} application")
  else
    raise "Unable to generate a Rails application:\n#{@terminal.output}"
  end
end

When /^I run the errornot generator with "([^\"]*)"$/ do |generator_args|
  if rails3?
    When %{I run "script/rails generate errornot #{generator_args}"}
  else
    When %{I run "script/generate errornot #{generator_args}"}
  end
end

Given /^I have installed the "([^\"]*)" gem$/ do |gem_name|
  @terminal.install_gem(gem_name)
end

Given /^I have built and installed the "([^\"]*)" gem$/ do |gem_name|
  @terminal.build_and_install_gem(File.join(PROJECT_ROOT, "#{gem_name}.gemspec"))
end

When /^I configure my application to require the "([^\"]*)" gem$/ do |gem_name|
  if rails_manages_gems?
    config_gem(gem_name)
  elsif bundler_manages_gems?
    bundle_gem(gem_name)
  else
    File.open(environment_path, 'a') do |file|
      file.puts
      file.puts("require 'errornot_notifier'")
      file.puts("require 'errornot_notifier/rails'")
    end

    unless rails_finds_generators_in_gems?
      FileUtils.cp_r(File.join(PROJECT_ROOT, 'generators'), File.join(RAILS_ROOT, 'lib'))
    end
  end
end

When /^I run "([^\"]*)"$/ do |command|
  @terminal.cd(RAILS_ROOT)
  @terminal.run(command)
end

Then /^I should receive a Errornot notification$/ do
  Then %{I should see "[ErrorNot Logger] Success: Net::HTTPOK"}
end

Then /^I should receive two Errornot notifications$/ do
  @terminal.output.scan(/\[ErrorNot Logger\] Success: Net::HTTPOK/).size.should == 2
end

When /^I configure the Errornot shim$/ do
  if bundler_manages_gems?
    bundle_gem("sham_rack")
  end
  shim_file = File.join(PROJECT_ROOT, 'features', 'support', 'errornot_shim.rb.template')
  if rails_supports_initializers?
    target = File.join(RAILS_ROOT, 'config', 'initializers', 'errornot_shim.rb')
    FileUtils.cp(shim_file, target)
  else
    File.open(environment_path, 'a') do |file|
      file.puts
      file.write IO.read(shim_file)
    end
  end
end

When /^I configure the notifier to use "([^\"]*)" as an API key and "([^\"]*)" as host$/ do |api_key, host|
  config_file = File.join(RAILS_ROOT, 'config', 'initializers', 'errornot.rb')
  if rails_manages_gems?
    requires = ''
  else
    requires = "require 'errornot_notifier'"
  end

  initializer_code = <<-EOF
    #{requires}
    ErrornotNotifier.configure do |config|
      config.api_key = #{api_key.inspect}
      config.host = #{host.inspect}
    end
  EOF

  if rails_supports_initializers?
    File.open(config_file, 'w') { |file| file.write(initializer_code) }
  else
    File.open(environment_path, 'a') do |file|
      file.puts
      file.puts initializer_code
    end
  end
end

Then /^I should see "([^\"]*)"$/ do |expected_text|
  unless @terminal.output.include?(expected_text)
    raise("Got terminal output:\n#{@terminal.output}\n\nExpected output:\n#{expected_text}")
  end
end

Then /^I should not see "([^\"]*)"$/ do |unexpected_text|
  if @terminal.output.include?(unexpected_text)
    raise("Got terminal output:\n#{@terminal.output}\n\nDid not expect the following output:\n#{unexpected_text}")
  end
end

When /^I uninstall the "([^\"]*)" gem$/ do |gem_name|
  @terminal.uninstall_gem(gem_name)
end

When /^I unpack the "([^\"]*)" gem$/ do |gem_name|
  if bundler_manages_gems?
    @terminal.cd(RAILS_ROOT)
    @terminal.run("bundle pack")
  elsif rails_manages_gems?
    @terminal.cd(RAILS_ROOT)
    @terminal.run("rake gems:unpack GEM=#{gem_name}")
  else
    vendor_dir = File.join(RAILS_ROOT, 'vendor', 'gems')
    FileUtils.mkdir_p(vendor_dir)
    @terminal.cd(vendor_dir)
    @terminal.run("gem unpack #{gem_name}")
    gem_path =
      Dir.glob(File.join(RAILS_ROOT, 'vendor', 'gems', "#{gem_name}-*", 'lib')).first
    File.open(environment_path, 'a') do |file|
      file.puts
      file.puts("$: << #{gem_path.inspect}")
    end
  end
end

When /^I install cached gems$/ do
  if bundler_manages_gems?
    When %{I run "bundle install"}
  end
end

When /^I install the "([^\"]*)" plugin$/ do |plugin_name|
  FileUtils.mkdir_p("#{RAILS_ROOT}/vendor/plugins/#{plugin_name}")
end

When /^I define a response for "([^\"]*)":$/ do |controller_and_action, definition|
  controller_class_name, action = controller_and_action.split('#')
  controller_name = controller_class_name.underscore
  controller_file_name = File.join(RAILS_ROOT, 'app', 'controllers', "#{controller_name}.rb")
  File.open(controller_file_name, "w") do |file|
    file.puts "class #{controller_class_name} < ApplicationController"
    file.puts "def consider_all_requests_local; false; end"
    file.puts "def local_request?; false; end"
    file.puts "def #{action}"
    file.puts definition
    file.puts "end"
    file.puts "end"
  end
end

When /^I perform a request to "([^\"]*)"$/ do |uri|
  if rails_uses_rack?
    request_script = <<-SCRIPT
      require 'config/environment'
      env = Rack::MockRequest.env_for(#{uri.inspect})
      RailsRoot::Application.call(env)
    SCRIPT
    File.open(File.join(RAILS_ROOT, 'request.rb'), 'w') { |file| file.write(request_script) }
    @terminal.cd(RAILS_ROOT)
    @terminal.run("./script/rails runner -e production request.rb")
  else
    uri = URI.parse(uri)
    request_script = <<-SCRIPT
      require 'cgi'
      class CGIWrapper < CGI
        def initialize(*args)
          @env_table = {}
          @stdinput = $stdin
          super(*args)
        end
        attr_reader :env_table
      end
      $stdin = StringIO.new("")
      cgi = CGIWrapper.new
      cgi.env_table.update({
        'HTTPS'          => 'off',
        'REQUEST_METHOD' => "GET",
        'HTTP_HOST'      => #{[uri.host, uri.port].join(':').inspect},
        'SERVER_PORT'    => #{uri.port.inspect},
        'REQUEST_URI'    => #{uri.request_uri.inspect},
        'PATH_INFO'      => #{uri.path.inspect},
        'QUERY_STRING'   => #{uri.query.inspect}
      })
      require 'dispatcher' unless defined?(ActionController::Dispatcher)
      Dispatcher.dispatch(cgi)
    SCRIPT
    File.open(File.join(RAILS_ROOT, 'request.rb'), 'w') { |file| file.write(request_script) }
    @terminal.cd(RAILS_ROOT)
    @terminal.run("./script/runner -e production request.rb")
  end
end

Then /^I should receive the following Errornot notification:$/ do |table|
  exceptions = @terminal.output.scan(%r{Recieved the following exception:\n([^\n]*)\n}m)
  exceptions.should_not be_empty

  doc = exceptions.last[0]

  hash = table.transpose.hashes.first

  doc.should be_include("error[message]=#{URI.escape(hash['error message'], Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))}")
  doc.should be_include("error[request][url]=#{URI.escape(hash['url'], Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))}")

  doc.should be_include("error[request][component]=#{URI.escape(hash['component'], Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))}") if hash['component']
  doc.should be_include("error[request][action]=#{URI.escape(hash['action'], Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))}") if hash['action']

  if hash['session']
    sessions = hash['session'].split(': ')
    sessions.each_slice(2).each do |session|
      doc.should be_include("error[session][#{session[0]}]=#{URI.escape(session[1], Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))}")
    end
  end

  if hash['parameters']
    params = hash['parameters'].split(': ')
    params.each_slice(2).each do |param|
      doc.should be_include("error[request][params][#{param[0]}]=#{URI.escape(param[1], Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))}")
    end
  end
end

Then /^I should see the Rails version$/ do
  Then %{I should see "[Rails: #{rails_version}]"}
end

Then /^I should see that "([^\"]*)" is not considered a framework gem$/ do |gem_name|
  Then %{I should not see "[R] #{gem_name}"}
end

Then /^the command should have run successfully$/ do
  @terminal.status.should == 0
end

When /^I route "([^\"]*)" to "([^\"]*)"$/ do |path, controller_action_pair|
  route = if rails3?
            %(match "#{path}", :to => "#{controller_action_pair}")
          else
            controller, action = controller_aciton_pair.split('#')
            %(map.connect "#{path}", :controller => "#{controller}", :action => "#{action}")
          end
  routes_file = File.join(RAILS_ROOT, "config", "routes.rb")
  File.open(routes_file, "r+") do |file|
    content = file.read
    content.gsub!(/^end$/, "  #{route}\nend")
    file.rewind
    file.write(content)
  end
end
