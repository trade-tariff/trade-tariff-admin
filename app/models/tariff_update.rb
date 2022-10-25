class TariffUpdate
  include Her::JsonApi::TariffModel
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

  ROLLBACK_APPLICABLE_STATES = %w[A].freeze

  def state
    STATES[super]
  end

  def rollback?
    attributes[:state].in?(ROLLBACK_APPLICABLE_STATES)
  end

  def issue_date
    Date.parse(attributes[:issue_date])
  end

  def applied_at
    Time.zone.parse(super) if super.present?
  end

  def id
    filename&.sub(/\.(xml|gzip)\Z/, '')
  end

  def formatted_update_type
    update_type.sub(/\ATariffSynchronizer::/, '').titleize
  end

  def inserts
    attributes[:inserts] ? TariffUpdate::Inserts.new(attributes[:inserts]) : nil
  end
end
