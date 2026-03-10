require 'client_builder'
require 'whodunnit_middleware'

Rails.application.config.http_client_uk = ClientBuilder.new('uk').call
Rails.application.config.http_client_xi = ClientBuilder.new('xi').call
