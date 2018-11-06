class AddRampClaimIdToRequestIssue < ActiveRecord::Migration[5.1]
  def change
    add_column :request_issues, :ramp_claim_id, :string
  end
end
