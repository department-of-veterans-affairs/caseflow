class RemoveRenamedDecisionIssueColumns < ActiveRecord::Migration[5.1]
  def change
    safety_assured do
      remove_column :decision_issues, :profile_date, :datetime
      remove_column :decision_issues, :promulgation_date, :datetime
    end
  end
end
