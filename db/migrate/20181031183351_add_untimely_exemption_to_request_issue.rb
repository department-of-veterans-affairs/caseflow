class AddUntimelyExemptionToRequestIssue < ActiveRecord::Migration[5.1]
  def change
    add_column :request_issues, :untimely_exemption, :boolean
    add_column :request_issues, :untimely_exemption_notes, :text
  end
end
