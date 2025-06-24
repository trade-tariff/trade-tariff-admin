class LiveIssue
  include ApiEntity
  uk_only

  attributes  :title,
              :description,
              :suggested_action,
              :commodities,
              :status,
              :date_discovered,
              :date_resolved,
              :updated_at
end
