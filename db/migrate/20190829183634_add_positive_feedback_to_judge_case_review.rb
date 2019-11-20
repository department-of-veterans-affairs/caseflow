# frozen_string_literal: true

class AddPositiveFeedbackToJudgeCaseReview < ActiveRecord::Migration[5.1]
  def up
    add_column :judge_case_reviews, :positive_feedback, :text, array: true, after: :areas_for_improvement
    change_column_default :judge_case_reviews, :positive_feedback, []
  end

  def down
    remove_column :judge_case_reviews, :positive_feedback
  end
end
