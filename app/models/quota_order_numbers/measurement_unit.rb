module QuotaOrderNumbers
  class MeasurementUnit
    include Her::JsonApi::Model

    attributes :description, :measurement_unit_code, :abbreviation
  end
end
