class ConfigurationsController < AuthenticatedController
  before_action :set_current_configuration, only: %i[edit update]

  def index
    authorize AdminConfiguration, :index?
    @configurations = AdminConfiguration.all.sort_by { |c| [c.config_type, c.name] }
  rescue Faraday::Error => e
    Rails.logger.error("Failed to fetch configurations: #{e.message}")
    @configurations = []
    flash.now[:alert] = "Unable to load configurations. Please try again."
  end

  def show
    authorize AdminConfiguration, :show?
    @configuration = find_configuration
    @versions = fetch_versions
  rescue Faraday::ResourceNotFound
    redirect_to configurations_path, alert: "Configuration not found."
  end

  def edit
    authorize AdminConfiguration, :update?
  rescue Faraday::ResourceNotFound
    redirect_to configurations_path, alert: "Configuration not found."
  end

  def update
    authorize AdminConfiguration, :update?

    @configuration.assign_attributes(configuration_params)

    if @configuration.save && @configuration.errors.empty?
      redirect_to configuration_path(@configuration),
                  notice: "Configuration updated."
    else
      render :edit
    end
  rescue Faraday::ResourceNotFound
    redirect_to configurations_path, alert: "Configuration not found."
  end

private

  def set_current_configuration
    @configuration = find_configuration(skip_oid: true)

    return if @configuration.current?

    redirect_to configuration_path(@configuration),
                alert: "Cannot edit historical versions."
  end

  def find_configuration(skip_oid: false)
    opts = {}
    opts[:oid] = params[:oid] if params[:oid].present? && !skip_oid

    AdminConfiguration.find(params[:name], opts)
  end

  def fetch_versions
    Version.all(item_type: "AdminConfiguration", item_id: params[:name])
  rescue Faraday::Error => e
    Rails.logger.error("Failed to fetch versions: #{e.message}")
    []
  end

  def configuration_params
    permitted = params.require(:configuration).permit(:value).to_h

    if permitted[:value].is_a?(String) && permitted[:value].match?(/\A\s*[\[{]/)
      begin
        permitted[:value] = JSON.parse(permitted[:value])
      rescue JSON::ParserError
        # keep as string
      end
    end

    permitted
  end
end
