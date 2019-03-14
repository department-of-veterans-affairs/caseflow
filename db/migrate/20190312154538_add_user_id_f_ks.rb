class AddUserIdFKs < ActiveRecord::Migration[5.1]
  def change
    [
     "advance_on_docket_motions",
     "appeal_views",
     "claims_folder_searches",
     "dispatch_tasks",
     "document_views",
     "end_product_establishments",
     "hearing_views",
     "intakes",
     "legacy_hearings",
     "organizations_users",
     "ramp_election_rollbacks",
     "reader_users",
     "request_issues_updates",
     "schedule_periods",
     "user_quotas",
    ].each do |tbl|
       add_foreign_key tbl, :users
    end
  end
end
