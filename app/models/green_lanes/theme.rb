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

    def label
      formatted_label.length > MAX_LENGTH ? "#{formatted_label[0...MAX_LENGTH]}..." : formatted_label
    end

    private

    def formatted_label
      "#{section}.#{subsection}. #{description}"
    end
  end
end
