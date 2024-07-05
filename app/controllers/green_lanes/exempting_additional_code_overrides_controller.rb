module GreenLanes
  class ExemptingAdditionalCodeOverridesController < AuthenticatedController
    include XiOnly

    before_action :disable_service_switching!
    before_action :check_service

    def new
      @exempting_additional_code_override = GreenLanes::ExemptingAdditionalCodeOverride.new
    end

    def create
      @exempting_additional_code_override = GreenLanes::ExemptingAdditionalCodeOverride.new(eaco_params)

      if @exempting_additional_code_override.valid? && @exempting_additional_code_override.save
        redirect_to green_lanes_exempting_overrides_path, notice: 'Exempting Additional Code Override created'
      else
        render :new
      end
    end

    def destroy
      @exempting_additional_code_override = GreenLanes::ExemptingAdditionalCodeOverride.find(params[:id])
      @exempting_additional_code_override.destroy

      redirect_to green_lanes_exempting_overrides_path, notice: 'Exempting Additional Code Override removed'
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
