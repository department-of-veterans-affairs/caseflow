class RequestIssue < ApplicationRecord
  self.ignored_columns = ["last_submitted_at"]
end

class DropRequestIssuesLastSubmittedAt < ActiveRecord::Migration[5.1]
  def change
    safety_assured { remove_column :request_issues, :last_submitted_at, :datetime }
  end
end
