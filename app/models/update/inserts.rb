class Update
  class Inserts
    def initialize(attributes)
      @attributes = attributes
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

    def updated_entities
      creates = inserts_for('create')
      updates = inserts_for('update')
      destroys = inserts_for('destroy')

      all_entities = Set.new
      all_entities.merge(creates.keys)
      all_entities.merge(updates.keys)
      all_entities.merge(destroys.keys)

      all_entities.each_with_object([]) do |entity, entities|
        entities << {
          entity:,
          creates: creates.dig(entity, 'count') || 0,
          updates: updates.dig(entity, 'count') || 0,
          destroys: destroys.dig(entity, 'count') || 0,
        }
      end
    end

    def any_updates?
      updated_entities.any?
    end

    def updated_inserts?
      parsed_inserts['total_duration'].present?
    end

    def parsed_inserts
      @parsed_inserts ||= JSON.parse(@attributes.presence || '{}')
    end

    private

    def inserts_for(operation)
      parsed_inserts.dig('operations', operation).except('duration', 'count', 'allocations')
    end
  end
end
