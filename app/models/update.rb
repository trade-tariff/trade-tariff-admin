class Update
  include ApiEntity

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
    if self[:filename].present?
      self[:filename].sub(/\.(xml|gzip)\Z/, '')
    else
      resource_id
    end
  end

  alias_method :to_param, :id

  def formatted_update_type
    self[:update_type]&.sub(/\ATariffSynchronizer::/, '')&.titleize
  end

  def inserts
    self[:inserts] ? Update::Inserts.new(self[:inserts]) : nil
  end
end
