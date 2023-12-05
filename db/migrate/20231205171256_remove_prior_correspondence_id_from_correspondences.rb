class RemovePriorCorrespondenceIdFromCorrespondences < Caseflow::Migration
  def change
    safety_assured { remove_column :correspondences, :prior_correspondence_id }
  end
end
