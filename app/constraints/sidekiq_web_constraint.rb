# Route constraint for Sidekiq Web. It uses the same session rules as
# the controller auth modules (NoAuth, BasicSessionAuth, PasswordlessAuth).
# With passwordless auth, only technical operators and superadmins match.
# When it returns false, the route does not match and the user gets a 404.
class SidekiqWebConstraint
  def matches?(request)
    case TradeTariffAdmin.auth_strategy
    when :none
      true
    when :basic
      request.session[:authenticated] == true
    when :passwordless
      technical_operator_session?(request)
    else
      false
    end
  end

private

  def technical_operator_session?(request)
    user_session = Session.find_by_token(request.session[:token])
    return false if user_session.nil?

    id_token_cookie = request.cookie_jar[TradeTariffAdmin.id_token_cookie_name]
    return false unless user_session.cookie_token_match_for?(id_token_cookie)
    return false unless user_session.current?

    user = user_session.user
    return false unless user.technical_operator?

    log_change_request(request, user)
    true
  end

  # Sidekiq Web is a Rack app, so lograge and PaperTrail do not record it.
  # Log who sent each request that can change Sidekiq data (retry, kill, delete).
  def log_change_request(request, user)
    return if request.get? || request.head?

    Rails.logger.info("[SidekiqWeb] #{request.request_method} #{request.original_fullpath} by user uid=#{user.uid} email=#{user.email}")
  end
end
