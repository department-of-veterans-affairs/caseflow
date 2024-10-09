class ChangeDecisionReviewsComments < ActiveRecord::Migration[5.2]
  def change
    change_table_comment :decision_reviews, "Decision Reviews"
  end
end
