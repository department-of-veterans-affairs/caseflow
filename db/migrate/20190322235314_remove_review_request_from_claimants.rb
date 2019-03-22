class RemoveReviewRequestFromClaimants < ActiveRecord::Migration[5.1]
  def change
    safety_assured do
      remove_column :claimants, :review_request_id, :integer
      remove_column :claimants, :review_request_type, :string
    end

    change_table_comment(:claimants, "The claimant for each Decision Review, and its payee_code if required.")

    change_column_comment(:claimants, :decision_review_id, "The ID of the Decision Review the claimant is on.")

    change_column_comment(:claimants, :decision_review_type, "The type of Decision Review the claimant is on.")

    change_column_comment(:claimants, :participant_id, "The participant ID of the claimant selected on a Decision Review.")

    change_column_comment(:claimants, :payee_code, "The payee_code for the claimant selected on a Decision Review, if applicable. Payee_code is required for claimants when the claim is processed in VBMS and the Veteran is not the claimant. For Supplemental Claims automatically created due to remanded decisions, this is automatically selected based on the last payee code used for the same claimant on a previous end product, if available.")
  end
end
