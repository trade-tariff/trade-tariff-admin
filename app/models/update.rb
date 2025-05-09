class Update
  include ApiEntity

  attr_accessor :update_type,
                :state,
                :issue_date,
                :created_at,
                :updated_at,
                :applied_at,
                :filesize,
                :filename,
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
    self[:state].in?(ROLLBACK_APPLICABLE_STATES)
  end

  def issue_date
    Date.parse(self[:issue_date])
  end

  def applied_at
    Time.zone.parse(self[:applied_at]) if self[:applied_at].present?
  end

  def id
    filename&.sub(/\.(xml|gzip)\Z/, '') || self[:id]
  end

  alias_method :to_param, :id

  def formatted_update_type
    update_type.sub(/\ATariffSynchronizer::/, '').titleize
  end

  def inserts
    self[:inserts] ? Update::Inserts.new(self[:inserts]) : nil
  end
end
