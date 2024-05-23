module GreenLanes
  class Theme
    include Her::JsonApi::Model
    use_api Her::XI_API

    MAX_LENGTH = 50

    attributes :section,
               :subsection,
               :theme,
               :description,
               :category

    collection_path '/admin/green_lanes/themes'

    def code
      "#{section}.#{subsection}"
    end

    def label
      formatted_label.truncate(MAX_LENGTH).to_s
    end

    private

    def formatted_label
      "#{section}.#{subsection}. #{description}"
    end
  end
end
