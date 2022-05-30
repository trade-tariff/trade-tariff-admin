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

  ROLLBACK_APPLICABLE_STATES = %w[A].freeze

  def state
    STATES[super]
  end

  def parsed_inserts
    JSON.parse(inserts.presence || '{}')
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

  def updated_inserts?
    parsed_inserts['total_duration'].present?
  end

  def total_duration_in_seconds
    parsed_inserts.fetch('total_duration', 0) / 1000 # in milliseconds
  end

  def total_records_affected
    parsed_inserts.fetch('total_count', 0)
  end

  def total_records_created
    parsed_inserts.dig('operations', 'create', 'count').presence || 0
  end

  def total_records_updated
    parsed_inserts.dig('operations', 'update', 'count').presence || 0
  end

  def total_records_destroyed
    parsed_inserts.dig('operations', 'destroy', 'count').presence || 0
  end

  def total_records_destroyed_missing
    parsed_inserts.dig('operations', 'destroy_missing', 'count').presence || 0
  end

  def total_records_destroyed_cascade
    parsed_inserts.dig('operations', 'destroy_cascade', 'count').presence || 0
  end

  def entity_updates
    creates = inserts_for('create')
    updates = inserts_for('update')
    destroys = inserts_for('destroy')
    destroys_missing = inserts_for('destroy_missing')
    destroys_cascade = inserts_for('destroy_cascade')

    all_entities = Set.new
    all_entities.merge(creates.keys)
    all_entities.merge(updates.keys)
    all_entities.merge(destroys.keys)
    all_entities.merge(destroys_missing.keys)
    all_entities.merge(destroys_cascade.keys)

    all_entities.each_with_object([]) do |entity, entities|
      # entity name, created, updated, destroyed, missing
      entities << {
        entity:,
        creates: creates.dig(entity, 'count') || 0,
        updates: updates.dig(entity, 'count') || 0,
        destroys: destroys.dig(entity, 'count') || 0,
        missing: destroys_missing.dig(entity, 'count') || 0,
      }
    end
  end

  def inserts_for(operation)
    parsed_inserts.dig('operations', operation).except('duration', 'count', 'allocations')
  end
end
