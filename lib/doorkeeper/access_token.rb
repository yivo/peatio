# Extend Doorkeeper::AccessToken to add a new access token type:
#   urn:peatio:api:v2:token
#
# This type will return APIv2 token in format "<access_key>:<secret_key>", then
# users can authenticate themselves using the keys and APIv2 authentication
# protocol.

module Doorkeeper
  class AccessToken
    paranoid

    attr_accessor :api_token

    after_create :link_api_token

    def token_type
      'urn:peatio:api:v2:token'
    end

    def revoke(clock = DateTime)
      transaction do
        super
        self.api_token = APIToken.from_oauth_token(self)
        api_token.try(:destroy)
      end
    end

  private

    def generate_token
      scopes = self.scopes.to_s
      raise "Invalid scope: #{scopes}" if scopes == 'all'

      member         = Member.find(resource_owner_id)
      self.api_token = member.api_tokens.create!(label: application.name, scopes: scopes)
      self.token     = api_token.to_oauth_token
    end

    def link_api_token
      api_token.update_attributes(oauth_access_token_id: id, expires_at: expired_time)
    end
  end
end
