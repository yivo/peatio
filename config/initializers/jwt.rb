unless ENV['JWT_PUBLIC_KEY'].blank?
  if APIv2::Auth::Utils.jwt_public_key.private?
    raise ArgumentError, 'JWT_PUBLIC_KEY was set to private key, however it should be public.'
  end
end

require 'yaml'
require 'openssl'

(YAML.load_file('config/management_api_v1.yml') || {}).deep_symbolize_keys.tap do |x|
  x.fetch(:keychain).each do |id, key|
    key = OpenSSL::PKey.read(Base64.urlsafe_decode64(key.fetch(:value)))
    if key.private?
      raise ArgumentError, 'keychain.' + id.to_s + ' was set to private key, ' \
                           'however it should be public (in config/management_api_v1.yml).'
    end
    x[:keychain][id] = key
  end

  x.fetch(:scopes).values.each do |scope|
    scope[:permitted_signers] = scope.fetch(:permitted_signers, []).map(&:to_sym)
    scope[:mandatory_signers] = scope.fetch(:mandatory_signers, []).map(&:to_sym)
  end

  ManagementAPIv1::JWTAuthenticationMiddleware.security_configuration = x
end
