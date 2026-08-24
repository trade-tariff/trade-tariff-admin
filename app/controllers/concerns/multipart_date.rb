module MultipartDate
  extend ActiveSupport::Concern

  included do
    helper_method :multipart_date_keys,
                  :multipart_date_params,
                  :compose_date,
                  :compose_date_params
  end

  def multipart_date_keys(date_params)
    keys = []
    date_params.each do |param|
      [1, 2, 3].each do |i|
        keys.push("#{param}(#{i}i)")
      end
    end
    keys
  end

  def multipart_date_params(date_params)
    multipart_date_keys(date_params).index_with { [] }
  end

  def compose_date(hash, date_param)
    year = params.dig(hash, "#{date_param}(1i)")
    month = params.dig(hash, "#{date_param}(2i)")
    day = params.dig(hash, "#{date_param}(3i)")

    return nil if [year, month, day].all?(&:blank?)

    "#{year}-#{month}-#{day}"
  rescue StandardError
    nil
  end

  def compose_date_params(permitted_params:, hash:, date_params:)
    params_to_remove = multipart_date_keys(date_params)
    params_to_add = {}

    date_params.each do |param|
      params_to_add[param] = compose_date(hash, param)
    end

    permitted_params
      .merge(params_to_add)
      .except(*params_to_remove)
  end
end
