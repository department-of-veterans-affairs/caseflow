# frozen_string_literal: true

class PostDecisionMotionUpdater
  include ActiveModel::Model

  attr_reader :task, :params

  def initialize(task, params)
    @task = task
    @params = params
  end

  def process
    ActiveRecord::Base.transaction do
      motion = create_motion
      return unless motion

      create_new_tasks
      create_request_issues if grant_type?
    end
  end

  private

  def create_motion
    motion = PostDecisionMotion.new(
      task: task,
      disposition: disposition,
      vacate_type: params[:vacate_type]
    )

    if params.key?(:vacated_decision_issue_ids)
      motion.vacated_decision_issue_ids = params[:vacated_decision_issue_ids]
    end

    unless motion.valid?
      errors.messages.merge!(motion.errors.messages)
      return
    end

    motion.save
  end

  def create_new_tasks
    # We create an AbstractMotionToVacateTask as sibling to the judge task
    # to serve as parent for all successive tasks. It is created when associated with
    # the new task in order to pass responsibility for validation to child task

    abstract_task = create_abstract_task
    unless abstract_task.valid?
      errors.messages.merge!(abstract_task.errors.messages)
      return
    end

    if grant_type?
      judge_sign_task = create_judge_sign_task(abstract_task)
    end

    new_task = create_new_task((judge_sign_task || abstract_task))

    unless new_task.valid?
      errors.messages.merge!(new_task.errors.messages)
      return
    end
    new_task.save

    task.update(status: Constants.TASK_STATUSES.completed)
  end

  def create_abstract_task
    AbstractMotionToVacateTask.new(
      appeal: task.appeal,
      parent: task.parent,
      assigned_to: task.assigned_to
    )
  end

  def create_new_task(parent)
    task_class.new(
      appeal: task.appeal,
      parent: parent,
      assigned_by: task.assigned_to,
      assigned_to: assigned_to,
      instructions: [params[:instructions]]
    )
  end

  def create_judge_sign_task(parent)
    JudgeSignMotionToVacateTask.new(
      appeal: task.appeal,
      parent: parent,
      assigned_to: task.assigned_to
    )
  end

  def create_request_issues
    params[:vacated_decision_issue_ids].map do |decision_issue_id|
      prev_decision_issue = DecisionIssue.find(decision_issue_id)
      RequestIssue.create!(
        decision_review: prev_decision_issue.decision_review,
        decision_review_type: prev_decision_issue.decision_review_type,
        contested_decision_issue_id: prev_decision_issue.id,
        contested_rating_issue_reference_id: prev_decision_issue.rating_issue_reference_id,
        contested_rating_issue_profile_date: prev_decision_issue.rating_profile_date,
        contested_issue_description: prev_decision_issue.description,
        nonrating_issue_category: prev_decision_issue.nonrating_issue_category,
        benefit_type: prev_decision_issue.benefit_type,
        decision_date: prev_decision_issue.caseflow_decision_date
      )
    end
  end

  def disposition
    case params[:disposition]
    when "partial"
      "partially_granted"
    else
      params[:disposition]
    end
  end

  def task_class
    @task_class ||= (task_type + "_task").classify.constantize
  end

  def task_type
    grant_type? ? params[:vacate_type] : "#{params[:disposition]}_motion_to_vacate"
  end

  def grant_type?
    %w[granted partial].include? params[:disposition]
  end

  def denied_or_dismissed?
    %w[denied dismissed].include? disposition
  end

  def assigned_to
    @assigned_to ||= (denied_or_dismissed? ? prev_motions_attorney : User.find_by(id: params[:assigned_to_id]))
  end

  def prev_motions_attorney
    mtv_mail_task.assigned_to
  end

  def prev_motions_attorney_or_org
    prev_motions_attorney.inactive? ? LitigationSupport.singleton : prev_motions_attorney
  end

  def mtv_mail_task
    task.parent
  end
end
