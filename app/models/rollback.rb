require 'concerns/her_paginatable'

class Rollback
  include Her::JsonApi::Model
  extend HerPaginatable

  attributes :id, :enqueued_at, :keep, :date, :user_id, :reason, :confirm_service

  validate :validate_service

  collection_path '/admin/rollbacks'

  def enqueued_at
    Time.zone.parse(super) if super.present?
  end

  def user=(user)
    self.user_id = user.id
  end

  def user
    @user ||= User.find_by(id: user_id)
  end

  def initialize_errors
    response_errors.each do |attribute, error_messages|
      Array(error_messages).each do |error_message|
        errors.add(attribute, error_message)
      end
    end
  end

  def validate_service
    if confirm_service.to_s.downcase != TradeTariffAdmin::ServiceChooser.service_name
      errors.add(:confirm_service, :wrong_service)
    end
  end
end
