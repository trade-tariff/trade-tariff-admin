module References
  class Export
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :include_ai_labels, :boolean, default: false
  end
end
