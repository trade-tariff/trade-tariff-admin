module GreenLanes
  class ExemptingAdditionalCodeOverridesController < AuthenticatedController
    include XiOnly

    def new
      @exempting_additional_code_override = GreenLanes::ExemptingAdditionalCodeOverride.new
    end

    def create
      @exempting_additional_code_override = GreenLanes::ExemptingAdditionalCodeOverride.build(eaco_params)
      @exempting_additional_code_override.save

      if @exempting_additional_code_override.errors.none?
        redirect_to green_lanes_exempting_overrides_path, notice: "Exempting Additional Code Override created"
      else
        render :new
      end
    end

    def destroy
      @exempting_additional_code_override = GreenLanes::ExemptingAdditionalCodeOverride.build(resource_id: params[:id])
      @exempting_additional_code_override.destroy

      redirect_to green_lanes_exempting_overrides_path, notice: "Exempting Additional Code Override removed"
    end

  private

    def eaco_params
      params.require(:exempting_additional_code_override).permit(
        :additional_code_type_id,
        :additional_code,
      )
    end
  end
end
