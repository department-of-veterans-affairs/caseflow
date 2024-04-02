class CreateCorrespondenceAppeals < Caseflow::Migration
  def change
    rename_table :correspondences_appeals, :correspondence_appeals
  end
end
end
