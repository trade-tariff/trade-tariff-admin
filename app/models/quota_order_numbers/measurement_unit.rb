module QuotaOrderNumbers
  class MeasurementUnit
    include ApiEntity

    attr_accessor :description, :measurement_unit_code, :abbreviation
  end
end
