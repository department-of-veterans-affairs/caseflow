class BackfillDistributionPriority < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    Distribution.unscoped.in_batches do |relation|
      relation.update_all priority_push: false
      sleep(0.1)
    end
  end
end
