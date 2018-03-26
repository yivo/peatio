module ManagementAPIv1
  class Mount < Grape::API
    PREFIX = '/management_api'

    version 'v1', using: :path

    cascade false

    format         :json
    content_type   :json, 'application/json'
    default_format :json

    do_not_route_options!

    helpers ManagementAPIv1::Helpers

    rescue_from(ManagementAPIv1::Exceptions::Base) { |e| error!(e.message, e.status, e.headers) }
    rescue_from(Grape::Exceptions::ValidationErrors) { |e| error!(e.message, 422) }

    use ManagementAPIv1::JWTAuthenticationMiddleware

    mount ManagementAPIv1::Deposits
  end
end
