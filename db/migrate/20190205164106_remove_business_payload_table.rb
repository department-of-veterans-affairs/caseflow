class RemoveBusinessPayloadTable < ActiveRecord::Migration[5.1]
  def change
    drop_table :task_business_payloads
  end
end
