module ErrornotNotifier
  # Sends out the notice to Errornot
  class Sender

    NOTICES_URI = '/errors'.freeze

    def initialize(options = {})
      [:proxy_host, :proxy_port, :proxy_user, :proxy_pass, :protocol,
        :host, :port, :secure, :http_open_timeout, :http_read_timeout].each do |option|
        instance_variable_set("@#{option}", options[option])
      end
    end

    # Methode extract from RestClient
    # maybe need some test
    def process_payload(p=nil, parent_key=nil)
      unless p.is_a?(Hash)
        p
      else
        p.keys.map do |k|
          key = parent_key ? "#{parent_key}[#{k}]" : k
          if p[k].is_a? Hash
            process_payload(p[k], key)
          elsif p[k].is_a? Array
            p[k].map do |v|
              value = URI.escape(v.to_s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
              "#{key}[]=#{value}"
            end
          else
            value = URI.escape(p[k].to_s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
            "#{key}=#{value}"
          end
        end.join("&")
      end
    end


    # Sends the notice data off to Errornot for processing.
    #
    # @param [String] data The XML notice to be sent off
    def send_to_errornot(data)
      logger.debug { "Sending request to #{url.to_s}:\n#{data}" } if logger

      http =
        Net::HTTP::Proxy(proxy_host, proxy_port, proxy_user, proxy_pass).
        new(url.host, url.port)

      http.read_timeout = http_read_timeout
      http.open_timeout = http_open_timeout
      http.use_ssl      = secure

      response = begin
                   # TODO see how use http.post or convert all to restclient
                   #RestClient.post(url.to_s, data)
                   data = process_payload(data)
                   http.post(url.path, data, HEADERS)
                 rescue TimeoutError => e
                   log :error, "Timeout while contacting the Errornot server."
                   nil
                 end

      case response
      when Net::HTTPSuccess then
        log :info, "Success: #{response.class}", response
      else
        log :error, "Failure: #{response.class}", response
      end
    end

    private

    attr_reader :proxy_host, :proxy_port, :proxy_user, :proxy_pass, :protocol,
      :host, :port, :secure, :http_open_timeout, :http_read_timeout

    def url
      URI.parse("#{protocol}://#{host}:#{port}").merge(NOTICES_URI)
    end

    def log(level, message, response = nil)
      logger.send level, LOG_PREFIX + message if logger
      ErrornotNotifier.report_environment_info
      ErrornotNotifier.report_response_body(response.body) if response && response.respond_to?(:body)
    end

    def logger
      ErrornotNotifier.logger
    end

  end
end
