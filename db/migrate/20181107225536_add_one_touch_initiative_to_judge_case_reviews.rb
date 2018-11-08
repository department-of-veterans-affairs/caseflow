class AddOneTouchInitiativeToJudgeCaseReviews < ActiveRecord::Migration[5.1]
  def change
    add_column :judge_case_reviews, :one_touch_initiative, :boolean
  end
end
