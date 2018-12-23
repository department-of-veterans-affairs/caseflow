class JudgeQualityReviewTask < JudgeTask
  def baseline_actions
    [Constants.TASK_ACTIONS.ASSIGN_TO_ATTORNEY.to_h, Constants.TASK_ACTIONS.MARK_COMPLETE.to_h]
  end

  def self.create_from_params(params, user)
    Task.find(params[:parent_id])&.update!(status: :on_hold)
    super(params, user)
  end

  def self.modify_params(params)
    super(params).merge(type: JudgeQualityReviewTask.name)
  end

  def update_from_params(params, _current_user)
    params[:instructions] = [instructions, params[:instructions]].flatten if params.key?(:instructions)

    update_status(params.delete(:status)) if params.key?(:status)
    update(params)

    [self]
  end

  def label
    COPY::JUDGE_QUALITY_REVIEW_TASK_LABEL
  end
end
