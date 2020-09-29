class BackfillRequestIssueType < ActiveRecord::Migration[5.2]
  def change
  	RequestIssue.unscoped.in_batches do |relation|
      relation.update_all type: "RequestIssue"
      sleep(0.1)
    end
  end
end
