class QuotaSearch
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveRecord::AttributeAssignment

  QUOTA_ORDER_NUMBER_LENGTH = 6

  validate :import_date_valid

  validates :order_number, numericality: true,
                           length: { is: QUOTA_ORDER_NUMBER_LENGTH }

  attribute :order_number
  attribute :import_date, :tariff_date

  delegate :day, :month, :year, to: :import_date, allow_nil: true

  private

  def import_date_valid
    errors.add(:import_date, :invalid_date) unless attributes.empty? || import_date.is_a?(Date)
  end
end
