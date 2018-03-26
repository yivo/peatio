require 'stringio'

module ManagementAPIv1
  class JWTAuthenticationMiddleware < Grape::Middleware::Base
    extend Memoist

    def before
      check_request_method!
      check_query_parameters!
      check_content_type!
      env['rack.input'] = StringIO.new(jwt.fetch('payload').to_json)
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
        message:       'Couldn\'t parse JWT',
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

    # TODO: Implement.
    def security_requirements
      endpoint.options[:route_options].yield_self do |o|
        { minimum_signatures_required: 1 }
      end
    end
  end
end
