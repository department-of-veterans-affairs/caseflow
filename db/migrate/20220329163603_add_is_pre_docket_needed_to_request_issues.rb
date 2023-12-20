class AddIsPreDocketNeededToRequestIssues < ActiveRecord::Migration[5.2]
  
  def change
    add_column :request_issues, :is_predocket_needed, :boolean, comment: "Indicates whether or not an issue has been selected to go to the pre-docket queue opposed to normal docketing."
  end
end
