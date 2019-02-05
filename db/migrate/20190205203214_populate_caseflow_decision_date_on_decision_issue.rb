class PopulateCaseflowDecisionDateOnDecisionIssue < ActiveRecord::Migration[5.1]
  def change
    DecisionIssue.find_each do |form8|
      form8.update(record_other_explanation: "Unknown") if form8.record_other_explanation == "{}"
    end
  end
end
