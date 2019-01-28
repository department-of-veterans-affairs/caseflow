class AddDecisionReviewRemandedToSupplementalClaims < ActiveRecord::Migration[5.1]
  def change
  	remove_column :supplemental_claims, :is_dta_error
  	add_reference :supplemental_claims, :decision_review_remanded, polymorphic: true, index: { name: "index_decision_issues_on_decision_review_remanded" }
  end
end
