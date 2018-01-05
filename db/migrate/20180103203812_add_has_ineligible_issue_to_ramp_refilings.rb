class AddHasIneligibleIssueToRampRefilings < ActiveRecord::Migration
  def change
    add_column :ramp_refilings, :has_ineligible_issue, :boolean
  end
end
