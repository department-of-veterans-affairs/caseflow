class AddDispositionToRequestIssues < ActiveRecord::Migration[5.1]
  def change
    add_column :request_issues, :disposition, :string
  end
end
