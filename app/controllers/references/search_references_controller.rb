module References
  class SearchReferencesController < AuthenticatedController
    RELEASE_SERVICES = %w[uk xi].freeze

    def index
      authorize SearchReference, :index?
      @search_references = search_reference_parent.search_references
    end

    def new
      authorize SearchReference, :create?
      @search_reference = SearchReference.new
      if release_service_params_present?
        assign_release_services_to_form(@search_reference)
      else
        assign_release_services_to_form(@search_reference, default: true)
      end
    end

    def create
      authorize SearchReference, :create?
      selected_services = selected_release_services

      if selected_services.empty?
        @search_reference = build_search_reference
        assign_release_services_to_form(@search_reference)
        @search_reference.errors.add(:release_services, "Select at least one service to release this reference")
        return render :new, status: :unprocessable_entity
      end

      failed_reference, = run_for_selected_services(selected_services) do
        reference = build_search_reference
        assign_release_services_to_form(reference)
        reference.save
        reference
      end

      if failed_reference
        @search_reference = failed_reference
        render :new, status: :unprocessable_entity
      else
        redirect_to [:references, search_reference_parent, :search_references], notice: "Search reference was successfully created."
      end
    end

    def edit
      authorize SearchReference, :update?
      if release_service_params_present?
        assign_release_services_to_form(search_reference_for_action)
      else
        assign_release_services_to_form(search_reference_for_action, default: true)
      end
    end

    def remove
      authorize SearchReference, :destroy?
      @search_reference = search_reference_for_action || SearchReference.new(title: original_title_param)
      if release_service_params_present?
        assign_release_services_to_form(@search_reference)
      else
        assign_release_services_to_form(@search_reference, default: true)
      end
    end

    def update
      authorize SearchReference, :update?
      selected_services = selected_release_services

      if selected_services.empty?
        @search_reference = search_reference_for_action || SearchReference.new(title: original_title_param)
        assign_release_services_to_form(@search_reference)
        @search_reference.errors.add(:release_services, "Select at least one service to release this reference")
        return render :edit, status: :unprocessable_entity
      end

      failed_reference, missing_services = run_for_selected_services(selected_services) do
        reference = search_reference_for_action
        next :missing if reference.blank?

        reference.build(title: normalised_title)
        assign_release_services_to_form(reference)
        reference.save
        reference
      end

      if failed_reference
        @search_reference = failed_reference
        render :edit, status: :unprocessable_entity
      else
        notice = "Search reference was successfully updated."
        notice = "#{notice} Not found in #{missing_services.map(&:upcase).join(', ')}." if missing_services.any?
        redirect_to [:references, search_reference_parent, :search_references], notice:
      end
    end

    def destroy
      authorize SearchReference, :destroy?
      selected_services = selected_release_services

      if selected_services.empty?
        @search_reference = search_reference_for_action || SearchReference.new(title: original_title_param)
        assign_release_services_to_form(@search_reference)
        @search_reference.errors.add(:release_services, "Select at least one service to release this reference")
        return render :remove, status: :unprocessable_entity
      end

      failed_reference, missing_services = run_for_selected_services(selected_services) do
        reference = search_reference_for_action
        next :missing if reference.blank?

        reference.destroy
        reference
      end

      if failed_reference
        redirect_to [:references, search_reference_parent, :search_references], alert: "Search reference could not be removed."
      else
        notice = "Search reference was successfully removed."
        notice = "#{notice} Not found in #{missing_services.map(&:upcase).join(', ')}." if missing_services.any?
        redirect_to [:references, search_reference_parent, :search_references], notice:
      end
    end

  private

    def search_reference_for_action
      @search_reference_for_action ||= begin
        search_reference_parent.search_references.find(params[:id]).tap do |reference|
          reference.referenced_id = search_reference_parent.id
        end
      rescue Faraday::ResourceNotFound
        fallback_reference_by_original_title
      end
    end
    helper_method :search_reference_for_action

    def search_reference
      @search_reference || search_reference_for_action
    end
    helper_method :search_reference

    def release_service_query_params
      {
        release_to_uk: release_service_selected?("uk") ? "1" : "0",
        release_to_xi: release_service_selected?("xi") ? "1" : "0",
      }
    end
    helper_method :release_service_query_params

    def release_service_selected?(service)
      key = service == "uk" ? :release_to_uk : :release_to_xi
      value = release_service_param(key)
      return true if value.nil?

      value.to_s == "1"
    end
    helper_method :release_service_selected?

    def normalised_title
      title = search_reference_params[:title] || ""

      SearchReferences::TitleNormaliser.normalise_title(title)
    end

    def search_reference_params
      params.require(:search_reference).permit(:title, :original_title, :release_to_uk, :release_to_xi)
    end

    def selected_release_services
      RELEASE_SERVICES.select do |service|
        release_service_selected?(service)
      end
    end

    def assign_release_services_to_form(reference, default: false)
      if default
        reference.release_to_uk = 1
        reference.release_to_xi = 1
        return
      end

      reference.release_to_uk = release_service_param(:release_to_uk).to_i
      reference.release_to_xi = release_service_param(:release_to_xi).to_i
    end

    def release_service_param(key)
      params.dig(:search_reference, key) || params[key]
    end

    def original_title_param
      params.dig(:search_reference, :original_title) || params[:original_title]
    end

    def release_service_params_present?
      release_service_param(:release_to_uk).present? || release_service_param(:release_to_xi).present?
    end

    def run_for_selected_services(selected_services)
      original_service_choice = TradeTariffAdmin::ServiceChooser.service_choice
      failed_reference = nil
      missing_services = []

      selected_services.each do |service|
        TradeTariffAdmin::ServiceChooser.service_choice = service
        @search_reference_for_action = nil

        reference = yield
        if reference == :missing
          missing_services << service
          next
        end

        if reference.respond_to?(:errors) && reference.errors.any?
          failed_reference = reference
          break
        end
      end

      [failed_reference, missing_services]
    ensure
      TradeTariffAdmin::ServiceChooser.service_choice = original_service_choice
      @search_reference_for_action = nil
    end

    def fallback_reference_by_original_title
      return nil if original_title_param.blank?

      search_reference_parent.search_references.detect do |entry|
        entry.title == original_title_param
      end
    end

    def search_reference_parent
      raise NotImplementedError, "Please override #search_reference_parent"
    end

    def build_search_reference
      search_reference_parent.search_references.build(title: normalised_title)
    end
  end
end
