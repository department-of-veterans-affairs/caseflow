class BackfillClaimantDecisionReviewData < ActiveRecord::Migration[5.1]
  def change
    safety_assured do
  	  execute "UPDATE claimants SET decision_review_id=review_request_id, decision_review_type=review_request_type"
	  end
  end
end
