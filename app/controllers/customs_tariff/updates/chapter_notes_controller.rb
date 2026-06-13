module CustomsTariff
  module Updates
    class ChapterNotesController < AuthenticatedController
      def new
        @update = CustomsTariff::Update.find(params[:update_version])
        authorize CustomsTariff::ChapterNote, :create?
        @chapter_id = params[:chapter_id]
        @section_id = params[:section_id]
        @chapter_note = CustomsTariff::ChapterNote.new(
          customs_tariff_update_version: params[:update_version],
          chapter_id: @chapter_id,
        )
      end

      def create
        @update = CustomsTariff::Update.find(params[:update_version])
        authorize CustomsTariff::ChapterNote, :create?
        @chapter_id = params[:chapter_id]
        @section_id = params[:section_id]

        CustomsTariff::ChapterNote.api.post(
          "admin/customs_tariff_updates/#{params[:update_version]}/chapter_notes",
          {
            data: {
              type: "customs_tariff_chapter_note",
              attributes: { chapter_id: @chapter_id, content: chapter_note_params[:content] },
            },
          },
        )

        redirect_to customs_tariff_update_section_chapter_notes_path(params[:update_version], @section_id),
                    notice: "Chapter note added."
      rescue Faraday::UnprocessableEntityError
        @chapter_note = CustomsTariff::ChapterNote.new(
          customs_tariff_update_version: params[:update_version],
          chapter_id: @chapter_id,
          content: chapter_note_params[:content],
        )
        render :new, status: :unprocessable_content
      end

      def index
        @update = CustomsTariff::Update.find(params[:update_version])
        authorize @update, :show?
        @section_id      = params[:section_id]
        @compare_version = params[:compare_version]
        @section         = Section.find(@section_id)
        @chapter_info    = @section.chapters.index_by(&:short_code)
        @chapter_notes   = CustomsTariff::ChapterNote.all(
          customs_tariff_update_version: params[:update_version],
          section_id: @section_id,
          compare_version: @compare_version,
        )
        notes_by_chapter = @chapter_notes.index_by(&:chapter_id)
        all_codes = (@chapter_info.keys + notes_by_chapter.keys).uniq.sort
        @rows = all_codes.map { |code| [code, notes_by_chapter[code]] }
      end

      def edit
        @update = CustomsTariff::Update.find(params[:update_version])
        @chapter_note = CustomsTariff::ChapterNote.find(
          params[:id],
          customs_tariff_update_version: params[:update_version],
        )
        authorize @chapter_note, :edit?
        @section_id      = params[:section_id]
        @compare_version = params[:compare_version]
      end

      def update
        @update = CustomsTariff::Update.find(params[:update_version])
        @chapter_note = CustomsTariff::ChapterNote.find(
          params[:id],
          customs_tariff_update_version: params[:update_version],
        )
        authorize @chapter_note, :update?
        @section_id      = params[:section_id]
        @compare_version = params[:compare_version]
        @chapter_note.build(content: chapter_note_params[:content])

        if @chapter_note.save && @chapter_note.errors.empty?
          redirect_to customs_tariff_update_section_chapter_notes_path(
            params[:update_version], @section_id
          ),
                      notice: "Chapter note updated."
        else
          render :edit
        end
      end

      def destroy
        @update = CustomsTariff::Update.find(params[:update_version])
        @chapter_note = CustomsTariff::ChapterNote.find(
          params[:id],
          customs_tariff_update_version: params[:update_version],
        )
        authorize @chapter_note, :destroy?
        @section_id = params[:section_id]
        @chapter_note.destroy
        redirect_to customs_tariff_update_section_chapter_notes_path(params[:update_version], @section_id),
                    notice: "Chapter note removed."
      rescue Faraday::ResourceNotFound
        redirect_to customs_tariff_update_section_chapter_notes_path(params[:update_version], @section_id),
                    alert: "Chapter note could not be found."
      end

      def preview
        authorize CustomsTariff::ChapterNote, :update?
        content = params.fetch(:content, "")
        render json: { html: GovspeakPreview.new(content, linkify_code_references: true).render }
      end

    private

      def chapter_note_params
        params.require(:customs_tariff_chapter_note).permit(:content)
      end
    end
  end
end
