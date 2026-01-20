module Notes
  module Chapters
    class ChapterNotesController < AuthenticatedController
      def new
        authorize ChapterNote, :create?
        @chapter_note = chapter.chapter_note
      end

      def create
        authorize ChapterNote, :create?
        @chapter_note = chapter.chapter_note.build(chapter_note_create_params.to_h.merge(chapter_id: chapter.id))

        if @chapter_note.valid? && @chapter_note.save
          redirect_to notes_section_chapters_url(section_id: chapter.section.id), notice: "Chapter note was successfully created."
        else
          render :new
        end
      end

      def edit
        @chapter_note = chapter.chapter_note
        authorize @chapter_note, :update?
      end

      def update
        @chapter_note = chapter.chapter_note
        authorize @chapter_note, :update?
        @chapter_note.build(chapter_note_update_params.to_h)

        if @chapter_note.valid? && @chapter_note.save
          redirect_to notes_section_chapters_url(section_id: chapter.section.id), notice: "Chapter note was successfully updated."
        else
          render :edit
        end
      end

      def destroy
        @chapter_note = chapter.chapter_note
        authorize @chapter_note, :destroy?
        @chapter_note.destroy

        redirect_to notes_section_chapters_url(section_id: chapter.section.id), notice: "Chapter note was successfully removed."
      end

    private

      def chapter
        @chapter ||= Chapter.find(params[:chapter_id])
      end
      helper_method :chapter

      def chapter_note_create_params
        params.require(:chapter_note).permit(:content, :chapter_id)
      end

      def chapter_note_update_params
        params.require(:chapter_note).permit(:content).merge(chapter_id: chapter.id)
      end
    end
  end
end
