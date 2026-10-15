class WhodunnitMiddleware < Faraday::Middleware
  def on_request(env)
    env.request_headers["X-Whodunnit"] = Current.whodunnit if Current.whodunnit.present?
    # URL-encoded because HTTP headers must be ASCII and names can contain other characters.
    env.request_headers["X-Whodunnit-Name"] = ERB::Util.url_encode(Current.whodunnit_name) if Current.whodunnit_name.present?
  end
end
