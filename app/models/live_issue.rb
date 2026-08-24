class LiveIssue
  include ApiEntity
  include FormattedDate
  uk_only

  attributes  :title,
              :description,
              :suggested_action,
              :commodities,
              :status,
              :date_discovered,
              :date_resolved,
              :updated_at

  def date_discovered=(value)
    @date_discovered = normalise_date(value)
  end

  def date_resolved=(value)
    @date_resolved = normalise_date(value)
  end

  def date_discovered
    initialise_date!(@date_discovered)
  end

  def date_resolved
    initialise_date!(@date_resolved)
  end
end
