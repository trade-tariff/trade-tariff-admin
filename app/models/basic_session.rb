class BasicSession
  include ActiveModel::Model

  attr_accessor :return_url, :password

  validates :return_url, presence: true
  validates :password, inclusion: { in: [TradeTariffAdmin.basic_password] }
end
