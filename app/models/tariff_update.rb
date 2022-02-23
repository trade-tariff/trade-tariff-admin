class TariffUpdate
  include Her::JsonApi::Model
  extend HerPaginatable

  collection_path '/admin/updates'

  attributes :update_type,
             :state,
             :issue_date,
             :created_at,
             :updated_at,
             :applied_at,
             :filesize,
             :exception_backtrace,
             :exception_class,
             :exception_queries,
             :file_presigned_url,
             :presence_errors

  STATES = {
    'A' => 'Applied',
    'P' => 'Pending',
    'F' => 'Failed',
  }.freeze

  ROLLBACK_APPLICABLE_STATES = %w[A P].freeze

  def state
    STATES[super]
  end

  def inserts
    JSON.parse(attributes[:inserts].presence || '{}')
  end

  def rollback?
    attributes[:state].in?(ROLLBACK_APPLICABLE_STATES)
  end

  def file_date
    if TradeTariffAdmin::ServiceChooser.xi?
      issue_date
    else
      filename.try :slice, 0, 10
    end
  end

  def issue_date
    Date.parse(attributes[:issue_date])
  end

  def applied_at
    Time.zone.parse(super) if super.present?
  end

  def id
    created_at.parameterize
  end
end
