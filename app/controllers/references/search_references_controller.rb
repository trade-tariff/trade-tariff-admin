module References
  class SearchReferencesController < AuthenticatedController
    before_action :authorize_user if TradeTariffAdmin.authenticate_with_sso?

    def index
      @search_references = search_reference_parent.search_references
    end

    def new
      @search_reference = SearchReference.new
    end

    def create
      @search_reference = build_search_reference

      if @search_reference.valid? && @search_reference.save
        redirect_to [:references, search_reference_parent, :search_references], notice: "Search reference was successfully created."
      else
        render :new
      end
    end

    def edit; end

    def update
      search_reference.build(title: normalised_title)

      if search_reference.valid? && search_reference.save
        redirect_to [:references, search_reference_parent, :search_references], notice: "Search reference was successfully updated."
      else
        render :edit
      end
    end

    def destroy
      search_reference.destroy

      redirect_to [:references, search_reference_parent, :search_references], notice: "Search reference was successfully removed."
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
      title = search_reference_params[:title] || ""

      SearchReferences::TitleNormaliser.normalise_title(title)
    end

    def search_reference_params
      params.require(:search_reference).permit(:title)
    end

    def search_reference_parent
      raise NotImplementedError, "Please override #search_reference_parent"
    end

    def build_search_reference
      search_reference_parent.search_references.build(title: normalised_title)
    end
  end
end
