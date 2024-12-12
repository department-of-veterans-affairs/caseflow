class AddSafeIndicesToCorrespondenceAppeals < ActiveRecord::Migration[6.1]
  include Caseflow::Migrations::AddIndexConcurrently

  def change
    add_safe_index :correspondence_appeals, :correspondence_id, name: "index on correspondence_id"
    add_safe_index :correspondence_appeals, :appeal_id, name: "index on appeal_id"
  end
end
