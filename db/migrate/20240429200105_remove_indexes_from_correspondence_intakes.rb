class RemoveIndexesFromCorrespondenceIntakes < ActiveRecord::Migration[6.0]
  def change
    remove_index :correspondence_intakes, column: "user_id", name: "index_on_user_id"
    remove_index :correspondence_intakes, column: "correspondence_id", name: "index_on_correspondence_id"
  end
end
