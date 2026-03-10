class WhodunnitMiddleware < Faraday::Middleware
  def on_request(env)
    env.request_headers["X-Whodunnit"] = Current.whodunnit if Current.whodunnit.present?
  end
end
