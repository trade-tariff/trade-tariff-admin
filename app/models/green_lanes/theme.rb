module GreenLanes
  class Theme
    include ApiEntity

    MAX_LENGTH = 50

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
