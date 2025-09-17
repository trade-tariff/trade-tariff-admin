module SearchReferences
  class TitleNormaliser
    def self.normalise_title(title = "")
      title.squish.downcase
    end
  end
end
