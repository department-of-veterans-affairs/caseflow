class AddIndexOnTaskIdToCorrespondenceIntakes < Caseflow::Migration
  def change
    add_safe_index :correspondence_intakes, [:task_id], name: "index on task_id"
  end
end
