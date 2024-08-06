module GreenLanes
  class UpdateNotification
    include Her::JsonApi::Model
    use_api Her::XI_API
    extend HerPaginatable

    attributes :measure_type_id,
               :regulation_id,
               :regulation_role,
               :status,
               :measure_type_description,
               :regulation_description,
               :regulation_url

    collection_path '/admin/green_lanes/update_notifications'
  end
end
