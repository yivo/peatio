module APIv2
  module Auth
    class JWTAuthenticator
      def initialize(token)
        @token_type, @token_value = token.to_s.split(' ')
      end

      def authenticate!
        raise AuthorizationError unless @token_type == 'Bearer'

        payload, header = decode_and_verify_token(@token_value)
        raise AuthorizationError unless payload

        raise AuthorizationError unless (member = fetch_member(payload))
        member
      end

    private

      def decode_and_verify_token(token)
        JWT.decode(token, Utils.jwt_shared_secret_key, true)
      rescue JWT::DecodeError => e
        Rails.logger.error { e.inspect }
        nil
      end

      def fetch_member(payload)
        return nil if payload['member_id'].blank?
        Member.find_by_id(payload['member_id'])
      end
    end
  end
end
