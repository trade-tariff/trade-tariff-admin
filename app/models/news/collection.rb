module News
  class Collection
    include Her::JsonApi::Model
    use_api Her::UK_API

    collection_path '/admin/news/collections'

    attributes :id, :name

    def id
      super.to_i
    end
  end
end
