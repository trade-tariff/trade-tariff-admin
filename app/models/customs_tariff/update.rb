module CustomsTariff
  class Update
    include ApiEntity

    attributes :version, :import_error, :validity_start_date, :validity_end_date,
               :source_url, :document_created_on, :created_at, :updated_at

    set_collection_path "admin/customs_tariff_updates"
    set_singular_path   "admin/customs_tariff_updates/:version"

    def failed? = import_error.present?
  end
end
