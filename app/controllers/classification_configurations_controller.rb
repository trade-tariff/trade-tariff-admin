class ClassificationConfigurationsController < AuthenticatedController
  before_action :restrict_to_non_production
  before_action :uk_only
  before_action :set_current_configuration, only: %i[edit update]

  def index
    authorize AdminConfiguration, :index?
    @configurations = AdminConfiguration.all.sort_by { |c| [c.config_type, c.name] }
  rescue Faraday::Error => e
    Rails.logger.error("Failed to fetch classification configurations: #{e.message}")
    @configurations = []
    flash.now[:alert] = "Unable to load configurations. Please try again."
  end

  def show
    authorize AdminConfiguration, :show?
    @configuration = find_configuration
  rescue Faraday::ResourceNotFound
    redirect_to classification_configurations_path, alert: "Configuration not found."
  end

  def edit
    authorize AdminConfiguration, :update?
  rescue Faraday::ResourceNotFound
    redirect_to classification_configurations_path, alert: "Configuration not found."
  end

  def update
    authorize AdminConfiguration, :update?

    @configuration.assign_attributes(configuration_params)

    if @configuration.save && @configuration.errors.empty?
      redirect_to classification_configuration_path(@configuration),
                  notice: "Configuration updated."
    else
      render :edit
    end
  rescue Faraday::ResourceNotFound
    redirect_to classification_configurations_path, alert: "Configuration not found."
  end

private

  def uk_only
    return if TradeTariffAdmin::ServiceChooser.uk?

    render "errors/not_found"
  end

  def restrict_to_non_production
    return if TradeTariffAdmin.environment.in?(%w[development staging])
    return if Rails.env.development?

    render "errors/not_found", status: :not_found
  end

  def set_current_configuration
    @configuration = find_configuration(skip_oid: true)

    return if @configuration.current?

    redirect_to classification_configuration_path(@configuration),
                alert: "Cannot edit historical versions."
  end

  def find_configuration(skip_oid: false)
    opts = {}
    opts[:oid] = params[:oid] if params[:oid].present? && !skip_oid

    AdminConfiguration.find(params[:name], opts)
  end

  def configuration_params
    permitted = params.require(:classification_configuration).permit(:value).to_h

    if permitted[:value].is_a?(String) && permitted[:value].start_with?("{")
      begin
        permitted[:value] = JSON.parse(permitted[:value])
      rescue JSON::ParserError
        # keep as string
      end
    end

    permitted
  end
end
