module References
  class ImportsController < AuthenticatedController
    def show
      @import_tasks = ImportTask.all.order(:created_at).first(5)
      @import_task = ImportTask.new
    end

    def create
      import_params = params[:import_task]
      if import_params.present?
        import_task = ImportTask.new(file: import_params[:file])
        if import_task.save
          ImportSearchReferencesJob.perform_later(import_task.id)
          return redirect_to(references_import_path, notice: 'References import have been scheduled')
        end
      end

      redirect_to references_import_path, alert: 'Please select a valid file'
    end
  end
end
