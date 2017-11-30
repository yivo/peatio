module APIv2
  module Auth
    class Middleware < ::Grape::Middleware::Base
      def before
        if provided?
          auth = Authenticator.new(request, params)
          @env['api_v2.token'] = auth.authenticate!
        end
      end

      def provided?
        env['HTTP_AUTHORIZATION'].present? ||
          # Just check for falsy values as it was previously (checking with #present breaks some tests).
          %i[ access_key tonce signature ].all? { |k| params[k] }
      end

      def request
        @request ||= ::Grape::Request.new(env)
      end

      def params
        @params ||= request.params
      end
    end
  end
end
