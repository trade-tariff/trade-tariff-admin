module News
  class Item
    include Her::JsonApi::Model
    use_api Her::UK_API

    DISPLAY_STYLE_REGULAR = 0

    collection_path '/admin/news/items'

    attributes :title,
               :slug,
               :precis,
               :content,
               :display_style,
               :show_on_uk,
               :show_on_xi,
               :show_on_home_page,
               :show_on_updates_page,
               :show_on_banner,
               :start_date,
               :end_date,
               :collection_ids

    after_initialize { self.collection_ids = [] unless collection_ids }

    def collection_ids=(ids)
      super Array.wrap(ids).map(&:presence).compact.map(&:to_i).uniq
    end

    def preview
      GovspeakPreview.new(content).render
    end
  end
end
