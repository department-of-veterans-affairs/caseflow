class RequestIssueEnumAsString < ActiveRecord::Migration[5.1]
  def up
    # add a new string column, convert the data, then drop the old column and rename the new
    add_column :request_issues, :ineligible_reason_str, :string
    execute "UPDATE request_issues SET ineligible_reason_str='duplicate_of_issue_in_active_review' WHERE ineligible_reason=0"
    execute "UPDATE request_issues SET ineligible_reason_str='untimely' WHERE ineligible_reason=1"
    execute "UPDATE request_issues SET ineligible_reason_str='previous_higher_level_review' WHERE ineligible_reason=2"
    remove_column :request_issues, :ineligible_reason
    rename_column :request_issues, :ineligible_reason_str, :ineligible_reason
  end

  def down
    add_column :request_issues, :ineligible_reason_int, :integer
    execute "UPDATE request_issues SET ineligible_reason_int=0 WHERE ineligible_reason='duplicate_of_issue_in_active_review'" 
    execute "UPDATE request_issues SET ineligible_reason_int=1 WHERE ineligible_reason='untimely'"
    execute "UPDATE request_issues SET ineligible_reason_int=2 WHERE ineligible_reason='previous_higher_level_review'"
    remove_column :request_issues, :ineligible_reason
    rename_column :request_issues, :ineligible_reason_int, :ineligible_reason
  end
end
