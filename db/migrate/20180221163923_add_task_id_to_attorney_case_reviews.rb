class AddTaskIdToAttorneyCaseReviews < ActiveRecord::Migration
  def change
    add_column :attorney_case_reviews, :task_id, :string
  end
end
