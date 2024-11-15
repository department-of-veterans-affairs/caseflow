class RemovePriorCorrespondenceIdFromCorrespondences < ActiveRecord::Migration[6.1]
  def change
    safety_assured { remove_column :correspondences, :prior_correspondence_id, :integer }
  end
end
