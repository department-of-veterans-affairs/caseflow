class AddCancellationReasonToTasks < Caseflow::Migration
  def change
    add_column :tasks, :cancellation_reason, :string,
               comment: "Reason for latest cancellation status"
  end
end
