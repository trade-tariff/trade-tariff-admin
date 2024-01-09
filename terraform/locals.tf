locals {
  service = "admin"
  api_service_backend_url_options = {
    uk = "http://backend-admin-uk.tariff.internal:8080"
    xi = "http://backend-admin-xi.tariff.internal:8080"
  }

  signon_url = var.environment == "production" ? "https://signon.publishing.service.gov.uk" : "https://signon.${var.base_domain}"
}
