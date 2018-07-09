class AddPartialClosureIssueIds < ActiveRecord::Migration[5.1]
  def change
    add_column :ramp_closed_appeals, :partial_closure_issue_sequence_ids, :string, array: true
  end
end
