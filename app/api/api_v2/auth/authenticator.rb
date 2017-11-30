module APIv2
  module Auth
    class Authenticator
      def initialize(request, params)
        @request = request
        @params  = params
      end

      def authenticate!
        if @request.env['HTTP_AUTHORIZATION'].present?
          begin
            token = @request.env['HTTP_AUTHORIZATION'].split(' ').last
            raise Auth0::NoTokenError if token.blank?
            payload, = Auth0::JWT.verify!(token)
            Auth0::PeatioAPITokenAdapter.new(token, payload)
          rescue Auth0::Error => e
            Rails.logger.error { e.inspect }
            raise AuthorizationError
          end
        else
          check_token!
          check_tonce!
          check_signature!
          self.token
        end
      end

      def token
        @token ||= APIToken.joins(:member).where(access_key: access_key).first
      end

      def access_key
        @params[:access_key]
      end

      def signature
        @params[:signature]
      end

      def tonce
        @params[:tonce].to_s.to_i
      end

      def check_token!
        raise InvalidAccessKeyError,  access_key unless token
        raise DisabledAccessKeyError, access_key if token.member.api_disabled
        raise ExpiredAccessKeyError,  access_key if token.expired?
        raise OutOfScopeError unless token.in_scopes?(route_scopes)
      end

      def check_signature!
        if signature != Utils.hmac_signature(token.secret_key, payload)
          Rails.logger.warn "APIv2 auth failed: signature doesn't match. token: #{token.access_key} payload: #{payload}"
          raise IncorrectSignatureError, signature
        end
      end

      def check_tonce!
        key = "api_v2:tonce:#{token.access_key}:#{tonce}"

        if Utils.cache.read(key)
          Rails.logger.warn "APIv2 auth failed: used tonce. token: #{token.access_key} payload: #{payload} tonce: #{tonce}"
          raise TonceUsedError.new(token.access_key, tonce)
        end

        # Mark tonce as used and remove it from cache after 61 seconds.
        Utils.cache.write(key, tonce, 61)

        now = Time.now.to_f * 1000
        # Ensure tonce's value is within 30 seconds.
        if tonce < now - 30000 || tonce > now + 30000
          Rails.logger.warn "APIv2 auth failed: invalid tonce. token: #{token.access_key} payload: #{payload} tonce: #{tonce} current timestamp: #{now}"
          raise InvalidTonceError.new(tonce, now)
        end
      end

      def payload
        "#{canonical_verb}|#{APIv2::Mount::PREFIX}#{canonical_path}|#{canonical_params}"
      end

      def canonical_verb
        @request.request_method.upcase
      end

      def canonical_path
        @request.path_info
      end

      def canonical_params
        denied = %w[ route_info format ].to_set
        URI.unescape \
          @params.reject { |k| denied.include?(k) }
                 .keys
                 .sort
                 .map { |k| [k, @params[k]] }
                 .to_h
                 .to_param
      end

      def endpoint
        @request.env['api.endpoint']
      end

      def route_scopes
        endpoint.options[:route_options][:scopes]
      end
    end
  end
end
