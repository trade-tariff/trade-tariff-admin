# Audit trail for distribution list changes. Recipients are identified by
# their Cognito username (sub), never by email address.
class CreateDistributionListAuditEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :distribution_list_audit_events do |t|
      t.string :actor_uid, null: false
      t.string :actor_name
      t.string :action, null: false
      t.string :group_name, null: false
      t.string :recipient_username, null: false
      t.datetime :created_at, null: false
    end

    add_index :distribution_list_audit_events, %i[group_name created_at], name: "index_dl_audit_events_on_group_name_and_created_at"
    add_index :distribution_list_audit_events, :recipient_username
  end
end
