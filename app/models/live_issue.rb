class LiveIssue
  include ApiEntity
  uk_only

  attributes  :id,
              :title,
              :description,
              :commodities,
              :status,
              :date_discovered,
              :date_resolved,
              :updated_at
end
