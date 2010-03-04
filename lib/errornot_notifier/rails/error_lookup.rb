module ErrornotNotifier
  module Rails
    module ErrorLookup

      # Sets up an alias chain to catch exceptions when Rails does
      def self.included(base) #:nodoc:
        base.send(:alias_method, :rescue_action_locally_without_errornot, :rescue_action_locally)
        base.send(:alias_method, :rescue_action_locally, :rescue_action_locally_with_errornot)
      end

      private

      def rescue_action_locally_with_errornot(exception)
        result = rescue_action_locally_without_errornot(exception)

        if ErrornotNotifier.configuration.development_lookup
          path   = File.join(File.dirname(__FILE__), '..', '..', 'templates', 'rescue.erb')
          notice = ErrornotNotifier.build_lookup_hash_for(exception, errornot_request_data)

          result << @template.render(
            :file          => path,
            :use_full_path => false,
            :locals        => { :host    => ErrornotNotifier.configuration.host,
                                :api_key => ErrornotNotifier.configuration.api_key,
                                :notice  => notice })
        end

        result
      end
    end
  end
end

