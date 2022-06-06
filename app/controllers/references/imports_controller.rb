module References
  class ImportsController < AuthenticatedController
    def show
      @import_tasks = ImportTask.all.order(:created_at).first(5)
    end

    def create
      import_task = ImportTask.new(file: params[:references_import][:file])
      if import_task.save
        ImportSearchReferencesJob.perform_later(import_task.id)
        redirect_to(references_import_path, notice: 'References import have been scheduled')
      else
        redirect_to(references_import_path, alert: import_task.errors.full_messages.to_sentence)
      end
    end
  end
end
