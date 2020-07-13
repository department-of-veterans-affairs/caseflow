# frozen_string_literal: true

class RenameFolderDateTimeofDecision < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      rename_column :legacy_issue_optins, :folder_date_time_of_decision, :folder_decision_date
      change_column :legacy_issue_optins, :folder_decision_date, :date, comment: "Decision date on case record folder"
    end
  end
end
