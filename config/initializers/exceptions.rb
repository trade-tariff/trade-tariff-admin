ActionDispatch::ExceptionWrapper.rescue_responses.merge!(
  'Faraday::ResourceNotFound' => :not_found,
  'Faraday::ClientError' => :bad_request,
  'Faraday::ServerError' => :internal_server_error,
  'ActionView::MissingTemplate' => :not_found,
  'ActionController::UnknownFormat' => :not_found,
  'AbstractController::ActionNotFound' => :not_found,
  'URI::InvalidURIError' => :not_found,
  'ActionController::RoutingError' => :not_found,
)
