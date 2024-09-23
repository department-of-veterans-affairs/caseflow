class ChangePriorCorrespondenceIdOnCorrespondences < Caseflow::Migration
  def change
    change_column_null :correspondences, :prior_correspondence_id, true
  end
end
