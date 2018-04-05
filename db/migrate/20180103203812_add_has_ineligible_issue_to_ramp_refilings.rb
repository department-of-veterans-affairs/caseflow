class AddHasIneligibleIssueToRampRefilings < ActiveRecord::Migration[5.1]
  def change
    add_column :ramp_refilings, :has_ineligible_issue, :boolean
  end
end
