class AddReferenceIdToRequestIssues < ActiveRecord::Migration[6.0]
  def change
    add_column :request_issues, :reference_id, :string, comment: "The ID of the decision review issue record internal to C&P."
  end
end
