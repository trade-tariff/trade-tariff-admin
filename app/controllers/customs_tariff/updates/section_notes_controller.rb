module CustomsTariff
  module Updates
    class SectionNotesController < AuthenticatedController
      def new
        @update = CustomsTariff::Update.find(params[:update_version])
        authorize CustomsTariff::SectionNote, :create?
        @section_id = params[:section_id]
        @section_note = CustomsTariff::SectionNote.new(
          customs_tariff_update_version: params[:update_version],
          section_id: @section_id,
        )
      end

      def create
        @update = CustomsTariff::Update.find(params[:update_version])
        authorize CustomsTariff::SectionNote, :create?
        @section_id = params[:section_id]

        CustomsTariff::SectionNote.api.post(
          "admin/customs_tariff_updates/#{params[:update_version]}/section_notes",
          {
            data: {
              type: "customs_tariff_section_note",
              attributes: { section_id: @section_id, content: section_note_params[:content] },
            },
          },
        )

        redirect_to customs_tariff_update_path(params[:update_version]),
                    notice: "Section note added."
      rescue Faraday::UnprocessableEntityError
        @section_note = CustomsTariff::SectionNote.new(
          customs_tariff_update_version: params[:update_version],
          section_id: @section_id,
          content: section_note_params[:content],
        )
        render :new, status: :unprocessable_content
      end

      def edit
        @update = CustomsTariff::Update.find(params[:update_version])
        @section_note = CustomsTariff::SectionNote.find(
          params[:id],
          customs_tariff_update_version: params[:update_version],
        )
        authorize @section_note, :edit?
      end

      def update
        @update = CustomsTariff::Update.find(params[:update_version])
        @section_note = CustomsTariff::SectionNote.find(
          params[:id],
          customs_tariff_update_version: params[:update_version],
        )
        authorize @section_note, :update?
        @section_note.build(content: section_note_params[:content])

        if @section_note.save && @section_note.errors.empty?
          redirect_to customs_tariff_update_path(params[:update_version]),
                      notice: "Section note updated."
        else
          render :edit
        end
      end

      def destroy
        @update = CustomsTariff::Update.find(params[:update_version])
        @section_note = CustomsTariff::SectionNote.find(
          params[:id],
          customs_tariff_update_version: params[:update_version],
        )
        authorize @section_note, :destroy?
        @section_note.destroy
        redirect_to customs_tariff_update_path(params[:update_version]),
                    notice: "Section note removed."
      rescue Faraday::ResourceNotFound
        redirect_to customs_tariff_update_path(params[:update_version]),
                    alert: "Section note could not be found."
      end

      def preview
        authorize CustomsTariff::SectionNote, :update?
        content = params.fetch(:content, "")
        formatted = TariffNoteFormatter.new(content).format
        render json: { html: GovspeakPreview.new(formatted).render }
      end

    private

      def section_note_params
        params.require(:customs_tariff_section_note).permit(:content)
      end
    end
  end
end
