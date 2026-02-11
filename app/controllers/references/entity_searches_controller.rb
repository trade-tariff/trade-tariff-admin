module References
  class EntitySearchesController < AuthenticatedController
    def index
      authorize SearchReference, :index?

      @query = params[:q].to_s.strip
      @results = References::EntitySearch.call(query: @query)
    end
  end
end
