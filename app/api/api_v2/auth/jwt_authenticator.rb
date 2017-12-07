module APIv2
  module Auth
    class JWTAuthenticator
      def initialize(token)
        @token_type, @token_value = token.to_s.split(' ')
      end

      #
      # Decodes and verifies JWT.
      # Returns authentic member email or raises an exception.
      #
      # @return [String]
      def authenticate!
        raise AuthorizationError unless @token_type == 'Bearer'

        payload, header = decode_and_verify_token(@token_value)

        fetch_email(payload)
      end

    private

      def decode_and_verify_token(token)
        JWT.decode(token, Utils.jwt_shared_secret_key, true)
      rescue JWT::DecodeError => e
        Rails.logger.error { e.inspect }
        raise AuthorizationError
      end

      # TODO: Check if email is well-formed.
      def fetch_email(payload)
        raise AuthorizationError if payload['email'].blank?
        payload['email']
      end
    end
  end
end
