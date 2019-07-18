OmniAuth.config.on_failure = Proc.new { |env|
  message_key = env['omniauth.error.type']
  error_description = Rack::Utils.escape(env['omniauth.error'].message)
  new_path = "#{env['SCRIPT_NAME']}#{OmniAuth.config.path_prefix}/failure?error_type=#{message_key}&error_msg=#{error_description}"
  Rack::Response.new(['302 Moved'], 302, 'Location' => new_path).finish
}

Rails.application.config.middleware.use OmniAuth::Builder do
  provider(
    :auth0,
    ENV['AUTH0_CLIENT_ID'],
    ENV['AUTH0_CLIENT_SECRET'],
    ENV['AUTH0_DOMAIN'],
    callback_path: "/auth/oauth2/callback",
    authorize_params: {
      scope: 'openid profile email',
      audience: "https://#{ENV['AUTH0_DOMAIN']}/userinfo"
    },
    provider_ignores_state: true
  )

  if Rails.env.development?
    provider(
      :developer,
      fields: [:email]
    )
  end
end
