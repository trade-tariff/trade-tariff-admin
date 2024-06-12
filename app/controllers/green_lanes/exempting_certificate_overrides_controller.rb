module GreenLanes
  class ExemptingCertificateOverridesController < AuthenticatedController
    include XiOnly

    before_action :disable_service_switching!
    before_action :check_service
    def index
      @exempting_certificate_overrides = GreenLanes::ExemptingCertificateOverride.all(page: current_page).fetch
    end

    def new
      @exempting_certificate_override = GreenLanes::ExemptingCertificateOverride.new
    end

    def create
      @exempting_certificate_override = GreenLanes::ExemptingCertificateOverride.new(eco_params)

      if @exempting_certificate_override.valid? && @exempting_certificate_override.save
        redirect_to green_lanes_exempting_certificate_overrides_path, notice: 'Exempting Certificate Override created'
      else
        render :new
      end
    end

    def destroy
      @exempting_certificate_override = GreenLanes::ExemptingCertificateOverride.find(params[:id])
      @exempting_certificate_override.destroy

      redirect_to green_lanes_exempting_certificate_overrides_path, notice: 'Exempting Certificate Override removed'
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
