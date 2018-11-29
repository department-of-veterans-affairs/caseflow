class AddUniqueIndexToRatingIssue < ActiveRecord::Migration[5.1]
  safety_assured

  def change
    add_column :rating_issues, :participant_id, :integer
    safety_assured { add_index(:rating_issues, [:reference_id, :participant_id], unique: true) }
  end
end
