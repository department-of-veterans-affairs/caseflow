# frozen_string_literal: true

class AttorneyDecisionTask < AttorneyTask
  class << self
    def create_many_from_params(params_array, _user)
      ActiveRecord::Base.multi_transaction do
        params_array.map do |params|
          judge_assign_task = JudgeAssignTask.find(params[:parent_id])
          judge_review_task = JudgeDecisionReviewTask.create!(judge_assign_task.slice(:appeal, :assigned_to, :parent))

          judge_assign_task.update!(status: Constants.TASK_STATUSES.completed)

          attorney_task = create!(params.merge(parent_id: judge_review_task.id))

          [attorney_task, judge_review_task, judge_assign_task]
        end.flatten
      end
    end
  end
end
