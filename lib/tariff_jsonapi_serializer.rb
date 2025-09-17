class TariffJsonapiSerializer < SimpleDelegator
  def initialize(entity)
    @entity = entity

    super
  end

  def serializable_hash
    serialized = { data: {} }
    serialized[:data][:id] = id if persisted?
    serialized[:data][:type] = type
    serialized[:data][:attributes] = attributes if attributes.any?

    serialized
  end

private

  attr_reader :entity

  def id
    resource_id
  end

  def type
    resource_type
  end

  def attributes
    super.except(
      :casted_by,
      :resource_id,
      :resource_type,
    )
  end
end
