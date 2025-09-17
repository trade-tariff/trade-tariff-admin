module GreenLanes
  class ExemptingCertificateOverridesController < AuthenticatedController
    include XiOnly

    def new
      @exempting_certificate_override = GreenLanes::ExemptingCertificateOverride.new
    end

    def create
      @exempting_certificate_override = GreenLanes::ExemptingCertificateOverride.new(eco_params)
      @exempting_certificate_override.save

      if @exempting_certificate_override.errors.none?
        redirect_to green_lanes_exempting_overrides_path, notice: "Exempting Certificate Override created"
      else
        render :new
      end
    end

    def destroy
      @exempting_certificate_override = GreenLanes::ExemptingCertificateOverride.build(resource_id: params[:id])
      @exempting_certificate_override.destroy

      redirect_to green_lanes_exempting_overrides_path, notice: "Exempting Certificate Override removed"
    end

  private

    def eco_params
      params.require(:exempting_certificate_override).permit(
        :certificate_type_code,
        :certificate_code,
      )
    end
  end
end
