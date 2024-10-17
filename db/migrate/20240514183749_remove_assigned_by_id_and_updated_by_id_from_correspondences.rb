class RemoveAssignedByIdAndUpdatedByIdFromCorrespondences < ActiveRecord::Migration[6.0]
  def change
    safety_assured do
      remove_column :correspondences, :assigned_by_id, :bigint
      remove_column :correspondences, :updated_by_id, :bigint
    end
  end
end
