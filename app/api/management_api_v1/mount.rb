# encoding: UTF-8
# frozen_string_literal: true

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

    rescue_from ManagementAPIv1::Exceptions::Base do |e|
      Rails.logger.error { e.inspect }
      error!(e.message, e.status, e.headers)
    end

    rescue_from Grape::Exceptions::ValidationErrors do |e|
      Rails.logger.error { e.inspect }
      Rails.logger.debug { e.full_messages }
      error!(e.message, 422)
    end

    rescue_from ActiveRecord::RecordNotFound do |e|
      Rails.logger.error { e.inspect }
      error!('Couldn\'t find record.', 404)
    end

    use ManagementAPIv1::JWTAuthenticationMiddleware

    mount ManagementAPIv1::Deposits
    mount ManagementAPIv1::Withdraws
    mount ManagementAPIv1::Tools

    # The documentation is accessible at http://localhost:3000/swagger?url=/management_api/v1/swagger
    add_swagger_documentation base_path:   PREFIX,
                              mount_path:  '/swagger',
                              api_version: 'v1',
                              doc_version: Peatio::VERSION,
                              info: {
                                title:       'Management API v1',
                                description: 'Management API is server-to-server API with high privileges.',
                                licence:     'MIT',
                                license_url: 'https://github.com/rubykube/peatio/blob/master/LICENSE.md' }
  end
end
