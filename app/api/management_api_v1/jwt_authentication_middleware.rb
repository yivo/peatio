require 'stringio'

module ManagementAPIv1
  class JWTAuthenticationMiddleware < Grape::Middleware::Base
    extend Memoist

    def before
      check_request_method!
      check_query_parameters!
      check_content_type!
      payload = check_jwt!(jwt)
      env['rack.input'] = StringIO.new(payload.to_json)
    end

  private

    def request
      Grape::Request.new(env)
    end
    memoize :request

    def jwt
      JSON.parse(request.body.read)
    rescue => e
      raise Exceptions::Authentication, \
        message:       'Couldn\'t parse JWT.',
        debug_message: e.inspect,
        status:        400
    end
    memoize :jwt

    def check_request_method!
      unless request.post? || request.put? || request.delete?
        raise Exceptions::Authentication, \
          message: 'Only POST, PUT, and DELETE verbs are allowed.',
          status:  405
      end
    end

    def check_query_parameters!
      unless request.GET.empty?
        raise Exceptions::Authentication, \
          message: 'Query parameters are not allowed.',
          status:  400
      end
    end

    def check_content_type!
      unless request.content_type == 'application/json'
        raise Exceptions::Authentication, \
          message: 'Only JSON body is accepted.',
          status:  400
      end
    end

    def check_jwt!(jwt)
      begin
        scope    = security_configuration.fetch(:scopes).fetch(security_scope)
        keychain = security_configuration.fetch(:keychain).slice(scope.fetch(:allowed_keys))
        minimum  = scope.fetch(:minimum_signatures_required)
        result   = JWT::Multisig.verify_jwt(jwt, keychain)
      rescue => e
        raise Exceptions::Authentication, \
          message:       'Failed to verify JWT.',
          debug_message: e.inspect,
          status:        400
      end

      if result[:verified] < minimum
        raise Exceptions::Authentication, \
          message: 'Not enough signatures for the action.',
          status:  401
      end

      result[:payload]
    end

    def security_scope
      endpoint.options.fetch(:route_options).fetch(:scope)
    end

    class << self
      extend Memoist

      def security_configuration
        YAML.load_file('config/management_api_v1.yml').deep_symbolize_keys
      end
      memoize :security_configuration
    end
  end
end
