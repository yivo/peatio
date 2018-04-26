module APIv2
  class Sessions < Grape::API
    helpers { include SessionUtils }

    before { authenticate! }

    use ActionDispatch::Session::RedisStore, \
        key:          '_peatio_session',
        expire_after: ENV.fetch('SESSION_LIFETIME').to_i

    helpers do
      def session
        env.fetch('rack.session')
      end
    end

    desc 'Create new user session.'
    post '/sessions' do
      session.destroy # This is used to initialize SID.
      destroy_member_sessions(current_user.id)

      # We assume everything is OK with authentication.
      session_lifetime = JSON.parse(JWT::Decode.base64url_decode(headers['Authorization'].split('.')[1]))['exp'].to_i - Time.now.to_i

      if session_lifetime > 0
        env['api_v2.session_lifetime'] = session_lifetime
        session[:member_id] = current_user.id
        memoize_member_session_id(current_user.id, session.id, expire_after: session_lifetime)
        status 204
      else
        status 422
      end
    end

    desc 'Delete all user sessions.'
    delete '/sessions' do
      destroy_member_sessions(current_user.id)
      status 200
    end
  end
end
