module CustomsTariff
  module Updates
    class ComparisonsController < AuthenticatedController
      before_action :require_compare_version

      def index
        @update = CustomsTariff::Update.find(params[:version])
        authorize @update, :show?
        @compare_version = params[:compare_version]
        @section_notes = CustomsTariff::SectionNote.all(
          customs_tariff_update_version: params[:version],
          compare_version: @compare_version,
        )
      end

      def show
        @update = CustomsTariff::Update.find(params[:update_version])
        authorize @update, :show?
        @compare_version = params[:compare_version]
        @section_note = CustomsTariff::SectionNote.find(
          params[:id],
          customs_tariff_update_version: params[:update_version],
          compare_version: @compare_version,
        )
      end

      def show_chapter_note
        @update = CustomsTariff::Update.find(params[:update_version])
        authorize @update, :show?
        @compare_version = params[:compare_version]
        @section_id = params[:section_id]
        @chapter_note = CustomsTariff::ChapterNote.find(
          params[:id],
          customs_tariff_update_version: params[:update_version],
          compare_version: @compare_version,
        )
      end

    private

      def require_compare_version
        return if params[:compare_version].present?

        redirect_to customs_tariff_update_path(params[:version] || params[:update_version]),
                    alert: "Please select a version to compare against."
      end
    end
  end
end
