class AddSafeIndicesToCorrespondencesAppeals < Caseflow::Migrations::AddIndexConcurrently
  def change
    add_safe_index :correspondences_appeals, [:correspondence_id], name: "index on correspondence_id"
    add_safe_index :correspondences_appeals, [:appeal_id], name: "index on appeal_id"
  end
end
