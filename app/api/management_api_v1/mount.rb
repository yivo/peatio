module ManagementAPIv1
  class Mount < Grape::API
    PREFIX = '/management_api'

    version 'v1', using: :path

    cascade false

    format         :json
    content_type   :json, 'application/json'
    default_format :json

    # helpers ManagementAPIv1::Helpers

    do_not_route_options!

    # use ManagementAPIv1::Auth::Middleware
    #
    # include Constraints
    # include ExceptionHandlers
    #
    # use ManagementAPIv1::CORS::Middleware
    #
    # mount ManagementAPIv1::Solvency
  end
end
