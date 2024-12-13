class AddRemandSourceIdToRequestIssues < ActiveRecord::Migration[6.1]
  def change
    add_column :request_issues, :remand_source_id, :bigint, comment: "ID of the original Decision Review with the remanded decision that generated this Remand Claim & Issue(s)"
  end
end
