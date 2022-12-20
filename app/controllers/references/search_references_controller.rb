module References
  class SearchReferencesController < AuthenticatedController
    before_action :authorize_user

    def index
      @search_references = search_reference_parent.search_references.all(page:, per_page:)
      @search_references = Kaminari.paginate_array(@search_references, total_count: @search_references.metadata[:pagination][:total]).page(page).per(per_page)
    end

    def new
      @search_reference = SearchReference.new
    end

    def create
      @search_reference = build_search_reference

      if @search_reference.valid? && @search_reference.save
        redirect_to [scope, search_reference_parent, :search_references], notice: 'Search reference was successfully created.'
      else
        render :new
      end
    end

    def edit; end

    def update
      search_reference.assign_attributes(title: normalised_title)

      if search_reference.valid? && search_reference.save
        redirect_to [scope, search_reference_parent, :search_references], notice: 'Search reference was successfully updated.'
      else
        render :edit
      end
    end

    def destroy
      search_reference.destroy

      redirect_to [scope, search_reference_parent, :search_references], notice: 'Search reference was successfully removed.'
    end

    def export
      export_service = SearchReference::ExportService.new(search_reference_parent.search_references)

      send_data export_service.to_csv, filename: search_reference_parent.export_filename
    end

    private

    def search_reference
      @search_reference ||= search_reference_parent.search_references.find(params[:id]).tap do |reference|
        reference.referenced_id = search_reference_parent.id
      end
    end
    helper_method :search_reference

    def authorize_user
      authorize SearchReference, :edit?
    end

    def normalised_title
      title = search_reference_params[:title] || ''

      SearchReferenceTitleNormaliser.normalise_title(title)
    end

    def search_reference_params
      params.require(:search_reference).permit(:title)
    end

    def page
      params.fetch(:page, 1)
    end

    def per_page
      params.fetch(:per_page, 200)
    end

    def search_reference_parent
      raise NotImplementedError, 'Please override #search_reference_parent'
    end

    def scope
      raise NotImplementedError, 'Please override #scope'
    end

    def build_search_reference
      search_reference_parent.search_references.build(title: normalised_title).tap do |reference|
        reference.referenced_id = search_reference_parent.id
      end
    end
  end
end
