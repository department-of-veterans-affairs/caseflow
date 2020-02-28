# frozen_string_literal: true

class DeNovoStreamCreator
  def initialize(appeal)
    @appeal = appeal
  end

  def call
    if appeal.vacate? && appeal.vacate_type == "vacate_and_de_novo"
      appeal.create_stream(:de_novo).tap do |de_novo_stream|
        appeal.decision_issues.map { |di| di.create_contesting_request_issue!(de_novo_stream) }
        create_new_stream_tasks(de_novo_stream)
      end
    end
  end

  private

  attr_reader :appeal

  def create_new_stream_tasks(stream)
    InitialTasksFactory.new(stream).create_root_and_sub_tasks!

    jdrt = JudgeDecisionReviewTask.create!(appeal: stream, parent: stream.root_task, assigned_to: judge_user)
    attorney_task = AttorneyTask.new(
      appeal: stream, parent: jdrt, assigned_by: judge_user, assigned_to: attorney_user
    )

    attorney_task.save
  end

  def judge_user
    judge_task&.assigned_to
  end

  def attorney_user
    return unless judge_task

    task = judge_task.children.find { |t| t.is_a?(AttorneyTask) && t.completed? }
    task.assigned_to
  end

  def judge_task
    appeal.tasks.find { |t| t.is_a?(JudgeDecisionReviewTask) && t.completed? }
  end
end
