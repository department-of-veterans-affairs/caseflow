class AddTaskIdToAttorneyCaseReviews < ActiveRecord::Migration[5.1]
  def change
    add_column :attorney_case_reviews, :task_id, :string
  end
end
