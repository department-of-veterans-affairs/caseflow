class RequestIssue < ApplicationRecord
  self.ignored_columns = ["removed_at"]
end

class DropRequestIssuesRemovedAt < ActiveRecord::Migration[5.1]
  def change
    safety_assured { remove_column :request_issues, :removed_at, :datetime }
  end
end
