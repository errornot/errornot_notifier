require File.dirname(__FILE__) + '/helper'
require 'rubygems'

require File.dirname(__FILE__) + '/../lib/errornot_tasks'
require 'fakeweb'

FakeWeb.allow_net_connect = false

class ErrornotTasksTest < Test::Unit::TestCase
  def successful_response(body = "")
    response = Net::HTTPSuccess.new('1.2', '200', 'OK')
    response.stubs(:body).returns(body)
    return response
  end

  def unsuccessful_response(body = "")
    response = Net::HTTPClientError.new('1.2', '200', 'OK')
    response.stubs(:body).returns(body)
    return response
  end

  context "being quiet" do
    setup { ErrornotTasks.stubs(:puts) }

    context "in a configured project" do
      setup { ErrornotNotifier.configure { |config| config.api_key = "1234123412341234" } }


      context "given an optional HTTP proxy and valid options" do
        setup do
          @response   = stub("response", :body => "stub body")
          @http_proxy = stub("proxy", :post_form => @response)

          Net::HTTP.expects(:Proxy).
            with(ErrornotNotifier.configuration.proxy_host,
                 ErrornotNotifier.configuration.proxy_port,
                 ErrornotNotifier.configuration.proxy_user,
                 ErrornotNotifier.configuration.proxy_pass).
            returns(@http_proxy)

          @options    = { :rails_env => "staging" }
        end
      end
    end

  end
end
