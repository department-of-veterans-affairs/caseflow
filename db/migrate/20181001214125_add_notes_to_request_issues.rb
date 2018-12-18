class AddNotesToRequestIssues < ActiveRecord::Migration[5.1]
  def change
    add_column :request_issues, :notes, :text
  end
end
