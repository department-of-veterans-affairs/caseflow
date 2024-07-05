class AddIndexesToCorrespondenceIntakes < Caseflow::Migration
  def change
    add_safe_index :correspondence_intakes, [:user_id], name: "index_on_user_id"
    add_safe_index :correspondence_intakes, [:correspondence_id], name: "index_on_correspondence_id"
  end
end
