module References
  class ImportsController < AuthenticatedController
    def show
      @import_tasks = ImportTask.all.order(:created_at).first(5)
      @import_task = ImportTask.new
    end

    def create
      import_task = ImportTask.new(file: params[:import_task][:file])
      if import_task.save
        ImportSearchReferencesJob.perform_later(import_task.id)
        redirect_to(references_import_path, notice: 'References import have been scheduled')
      else
        render show
      end
    end
  end
end
