# frozen_string_literal: true

class AddVerifiedUnidentifiedIssueToRequestIssues < ActiveRecord::Migration[5.1]
  def change
    add_column :request_issues, :verified_unidentified_issue, :boolean, comment: "A verified unidentified issue allows an issue whose rating data is missing to be intaken as a regular rating issue. In order to be marked as verified, a VSR needs to confirm that they were able to find the record of the decision for the issue."
  end
end
