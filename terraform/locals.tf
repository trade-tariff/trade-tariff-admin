locals {
  service = "admin"
  api_service_backend_url_options = {
    uk = "https://backend-uk.tariff.internal:8080"
    xi = "https://backend-xi.tariff.internal:8080"
  }

  govuk_app_domain = var.environment != "production" ? var.environment == "development" ? "tariff-admin-dev" : "tariff-admin-staging" : "tariff-admin"
}
