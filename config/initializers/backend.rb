require 'client_builder'

Rails.application.config.http_client_uk = ClientBuilder.new('uk').call
Rails.application.config.http_client_xi = ClientBuilder.new('xi').call
