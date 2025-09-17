module GreenLanes
  class ExemptionsController < AuthenticatedController
    include XiOnly

    def index
      @exemptions = GreenLanes::Exemption.all(page: current_page)
    end

    def new
      @exemption = GreenLanes::Exemption.new
    end

    def create
      @exemption = GreenLanes::Exemption.new(ex_params)
      @exemption.save

      if @exemption.errors.none?
        redirect_to green_lanes_exemptions_path, notice: "Exemption created"
      else
        render :new
      end
    end

    def edit
      @exemption = GreenLanes::Exemption.find(params[:id])
    end

    def update
      @exemption = GreenLanes::Exemption.build(ex_params.merge(resource_id: params[:id]))
      @exemption.save

      if @exemption.errors.none?
        redirect_to green_lanes_exemptions_path, notice: "Exemption updated"
      else
        render :edit
      end
    end

    def destroy
      @exemption = GreenLanes::Exemption.find(params[:id])
      @exemption.destroy

      redirect_to green_lanes_exemptions_path, notice: "Exemption removed"
    end

  private

    def ex_params
      params.require(:exemption).permit(
        :code,
        :description,
      )
    end
  end
end
