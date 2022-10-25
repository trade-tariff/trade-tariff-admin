class QuotaSearch
  include ActiveModel::Model

  QUOTA_ORDER_NUMBER_LENGTH = 6

  validates :order_number, presence: true,
                           length: { is: QUOTA_ORDER_NUMBER_LENGTH }

  def initialize(order_number = '')
  @order_number = order_number
  end

  attr_accessor :order_number
end
