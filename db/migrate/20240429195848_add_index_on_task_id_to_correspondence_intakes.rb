class AddIndexOnTaskIdToCorrespondenceIntakes < ActiveRecord::Migration[6.1]
  include Caseflow::Migrations::AddIndexConcurrently

  def change
    add_safe_index :correspondence_intakes, [:task_id], name: "index on task_id"
  end
end
