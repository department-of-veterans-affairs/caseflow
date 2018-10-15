class AddIsUnidentifiedToRequestIssues < ActiveRecord::Migration[5.1]
  def change
    add_column :request_issues, :is_unidentified, :boolean
  end
end
