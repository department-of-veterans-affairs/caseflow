class ChangeVhaDecisionReviewsToDecisionReviews < ActiveRecord::Migration[5.2]
  def change
    safety_assured { rename_table :vha_decision_reviews, :decision_reviews }
  end
end
