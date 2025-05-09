module GreenLanes
  class Theme
    include ApiEntity

    MAX_LENGTH = 50

    attr_accessor :section,
                  :subsection,
                  :theme,
                  :description,
                  :category

    set_collection_path '/admin/green_lanes/themes'

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
