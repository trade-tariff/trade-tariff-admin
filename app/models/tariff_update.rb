class TariffUpdate
  include Her::JsonApi::Model
  extend HerPaginatable

  collection_path '/admin/updates'

  attributes :update_type, :state, :issue_date, :created_at, :updated_at, :applied_at, :filesize,
             :exception_backtrace, :exception_class, :exception_queries,
             :file_presigned_url, :log_presigned_urls, :presence_errors

  STATES = {
    'A' => 'Applied',
    'M' => 'Missing',
    'P' => 'Pending',
    'F' => 'Failed',
  }.freeze

  def state
    STATES[super]
  end

  def update_type
    case attributes[:update_type]
    when /Taric/ then 'TARIC'
    when /Chief/ then 'CHIEF'
    when /Cds/   then 'CDS'
    end
  end

  def log_presigned_urls
    attributes[:log_presigned_urls] || {}
  end

  def missing?
    attributes[:state] == 'M'
  end

  def filename
    super unless missing?
  end

  def file_date
    if update_type == 'CDS'
      Date.parse(issue_date)
    else
      filename.try :slice, 0, 10
    end
  end

  def created_at
    Time.zone.parse(super)
  end

  def applied_at
    Time.zone.parse(super) if super.present?
  end

  def to_s
    "Applied #{update_type} at #{updated_at} (#{filename})"
  end

  def id
    created_at.to_s.parameterize
  end
end
