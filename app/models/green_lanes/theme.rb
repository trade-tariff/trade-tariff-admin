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
      "#{category} - #{short_theme}"
    end

    private

    def short_theme
      theme.length > MAX_LENGTH ? "#{theme[0...MAX_LENGTH]}..." : theme
    end
  end
end
