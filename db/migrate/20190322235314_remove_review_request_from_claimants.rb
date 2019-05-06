class RemoveReviewRequestFromClaimants < ActiveRecord::Migration[5.1]
  def change
    safety_assured do
      remove_column :claimants, :review_request_id
      remove_column :claimants, :review_request_type
    end

    change_table_comment(:claimants, "This table bridges decision reviews to participants when the participant is listed as a claimant on the decision review. A participant can be a claimant on multiple decision reviews.")

    change_column_comment(:claimants, :decision_review_id, "The ID of the decision review the claimant is on.")

    change_column_comment(:claimants, :decision_review_type, "The type of decision review the claimant is on.")

    change_column_comment(:claimants, :participant_id, "The participant ID of the claimant.")

    change_column_comment(:claimants, :payee_code, "The payee_code for the claimant, if applicable. payee_code is required when the claim is processed in VBMS.")
  end
end
