class BackfillRequestIssueType < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!


  def up
  	RequestIssue.unscoped.in_batches do |relation|
      relation.update_all type: "RequestIssue"
      sleep(0.1)
    end
  end

  def down
  end
end
