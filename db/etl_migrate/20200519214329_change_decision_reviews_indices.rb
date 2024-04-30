class ChangeDecisionReviewsIndices < Caseflow::Migration
  def change
    rename_index :decision_reviews, "idx_vha_decision_review_id_and_type", "idx_decision_review_id_and_type"
    rename_index :decision_reviews, "idx_vha_decision_review_remanded_id_and_type", "idx_decision_review_remanded_id_and_type"
  end
end
