module Sunspot
  module Rails

    module SolrInstrumentation
      extend ActiveSupport::Concern

      if RUBY_VERSION.to_i < 2
        included do
          alias_method_chain :send_and_receive, :as_instrumentation
        end

        def send_and_receive_with_as_instrumentation(path, opts)
          log_request_info(path, opts) do
            send_and_receive_without_as_instrumentation(path, opts)
          end
        end
      else

        module BetterInstrumentationLogger

          def send_and_receive(path, opts)
            log_request_info(path, opts) do
              super
            end
          end

        end

        included do
          prepend BetterInstrumentationLogger
        end

      end

      def log_request_info(path, opts)
        parameters = (opts[:params] || {})
        parameters.merge!(opts[:data]) if opts[:data].is_a? Hash
        payload = {:path => path, :parameters => parameters}
        ActiveSupport::Notifications.instrument("request.rsolr", payload) do
          yield
        end
      end

    end
  end
end