require 'rails/generators'

class ErrornotGenerator < Rails::Generators::Base

  class_option :api_key, :aliases => "-k", :type => :string, :desc => "Your Errornot API key"
  class_option :server, :type => :string, :desc => "Your host of Errornot"

  def self.source_root
    @_errornot_source_root ||= File.expand_path("../../../../generators/errornot/templates", __FILE__)
  end

  def install
    ensure_api_key_was_configured
    generate_initializer unless api_key_configured?
    test_errornot
  end

  private

  def ensure_api_key_was_configured
    if !options[:api_key]  && !api_key_configured?
      puts "Must pass --api-key or create config/initializers/errornot.rb"
      exit
    end
    if !options[:server]  && !api_key_configured?
      puts "Must pass --server or create config/initializers/errornot.rb"
      exit
    end
  end

  def api_key
    options[:api_key]
  end

  def generate_initializer
    template 'initializer.rb', 'config/initializers/errornot.rb'
  end

  def api_key_configured?
    File.exists?('config/initializers/errornot.rb')
  end

  def test_errornot
    puts run("rake errornot:test --trace")
  end
end
