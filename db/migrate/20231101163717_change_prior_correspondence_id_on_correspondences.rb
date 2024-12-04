class ChangePriorCorrespondenceIdOnCorrespondences < ActiveRecord::Migration[6.1]
  def change
    change_column_null :correspondences, :prior_correspondence_id, true
  end
end
