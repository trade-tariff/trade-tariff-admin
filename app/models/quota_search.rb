class QuotaSearch
  include ActiveModel::Model

  QUOTA_ORDER_NUMBER_LENGTH = 6

  validates :order_number, numericality: true,
                           length: { is: QUOTA_ORDER_NUMBER_LENGTH }

  attr_accessor :order_number
end
