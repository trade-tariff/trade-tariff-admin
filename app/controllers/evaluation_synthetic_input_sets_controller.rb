class EvaluationSyntheticInputSetsController < AuthenticatedController
  include UkOnly

  rescue_from Faraday::Error, with: :redirect_synthetic_input_set_unavailable

  def new
    authorize EvaluationSyntheticInputSet, :create?

    @synthetic_input_set = EvaluationSyntheticInputSet.new
  end

  # Unlike a gold query set, sampling finishes within this one request -- there is no
  # background generation to redirect away to poll for. The created set (and the items it
  # was sampled from) is rendered directly, rather than redirecting to a #show the backend
  # has no route for.
  def create
    authorize EvaluationSyntheticInputSet, :create?

    @synthetic_input_set = EvaluationSyntheticInputSet.new(synthetic_input_set_params)

    if @synthetic_input_set.save && @synthetic_input_set.errors.empty?
      render :show
    else
      render :new, status: :unprocessable_content
    end
  end

private

  def redirect_synthetic_input_set_unavailable
    redirect_to new_evaluation_synthetic_input_set_path, alert: "The synthetic input set could not be created. Try again."
  end

  def synthetic_input_set_params
    params.require(:evaluation_synthetic_input_set).permit(:name, :requested_size)
  end
end
