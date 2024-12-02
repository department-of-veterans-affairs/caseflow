class RemovePriorCorrespondenceIdFromCorrespondences < ActiveRecord::Migration[6.1]
  include Caseflow::Migrations::AddIndexConcurrently

  def up
    safety_assured { remove_column :correspondences, :prior_correspondence_id, :integer }
  end

  def down
    add_column :correspondences, :prior_correspondence_id, :integer, null: false
    add_safe_index :correspondences, [:prior_correspondence_id], name: "index_on_prior_correspondence_id"
  end
end
