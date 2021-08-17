class AddDecisionReviewValidation < Caseflow::Migration
  def change
    change_column_null(:claimants, :decision_review_id, false )
    change_column_null(:claimants, :decision_review_type, false )
  end
end
