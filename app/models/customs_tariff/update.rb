module CustomsTariff
  class Update
    include ApiEntity

    attributes :version, :status, :validity_start_date, :validity_end_date,
               :source_url, :document_created_on, :created_at, :updated_at

    set_collection_path "admin/customs_tariff_updates"
    set_singular_path   "admin/customs_tariff_updates/:version"

    def pending?  = status == "pending"
    def approved? = status == "approved"
    def rejected? = status == "rejected"

    def status_tag_colour
      { "pending" => "blue", "approved" => "green", "rejected" => "red" }.fetch(status, "grey")
    end
  end
end
