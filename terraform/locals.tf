locals {
  service = "admin"
  api_service_backend_url_options = {
    uk = "http://backend-uk.tariff.internal:8080"
    xi = "http://backend-xi.tariff.internal:8080"
  }

  govuk_app_domain = var.environment != "production" ? var.environment == "development" ? "tariff-admin-dev" : "tariff-admin-staging" : "tariff-admin"
  signon_url       = var.environment == "production" ? "https://signon.publishing.service.gov.uk" : "https://signon.${var.base_domain}"
}
