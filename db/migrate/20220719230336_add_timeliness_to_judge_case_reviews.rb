class AddTimelinessToJudgeCaseReviews < Caseflow::Migration
  def change

    add_column :judge_case_reviews, :timeliness, :string, comment: "Documents if the drafted decision by an attorney was provided on a timely or untimely manner."
  end
end
