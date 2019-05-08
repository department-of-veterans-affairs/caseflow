class AddUpdatedDescriptionToRequestIssues < ActiveRecord::Migration[5.1]
  def change
    add_column :request_issues, :updated_description, :string, comment: "The updated description for the contested issue, optionally entered by the user."
  end
end
