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
      raise ArgumentError, 'keychain.' + id + ' was set to private key, ' \
                           'however it should be public (in config/management_api_v1.yml).'
    end
    x[:keychain][id] = key
  end

  x.fetch(:scopes).each do |name, scope|
    n = scope.fetch(:minimum_signatures_required)
    if n < 1
      raise ArgumentError, 'scopes.' + name + '.minimum_signatures_required was set to ' + n + ', ' \
                           'however it should be at least 1 (in config/management_api_v1.yml).'
    end
  end

  ManagementAPIv1::JWTAuthenticationMiddleware.security_configuration = x
end
