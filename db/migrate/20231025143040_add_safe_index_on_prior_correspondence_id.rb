class AddSafeIndexOnPriorCorrespondenceId < Caseflow::Migration
  def change
    add_safe_index :correspondences, [:prior_correspondence_id], name: "index_on_prior_correspondence_id"
  end
end
