class AddVeteranFileNumberToRequestIssues < ActiveRecord::Migration[5.1]
  def change
    add_column :request_issues, :veteran_file_number, :string
  end
end
