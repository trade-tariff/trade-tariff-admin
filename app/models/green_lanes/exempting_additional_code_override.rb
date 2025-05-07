module GreenLanes
  class ExemptingAdditionalCodeOverride
    include ApiEntity

    xi_only

    attr_accessor :additional_code_type_id, :additional_code
  end
end
