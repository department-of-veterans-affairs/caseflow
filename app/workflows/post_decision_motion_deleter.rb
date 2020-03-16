# frozen_string_literal: true

##
# The PostDecisionMotionDeleter reverses the granting of a PostDecisionMotion by deleting it along
# with the new vacate stream, and assigning a new JudgeAddressMotionToVacateTask on the original
# appeal back to the original judge.

class PostDecisionMotionDeleter
  attr_reader :task, :instructions

  delegate :appeal, to: :task

  def initialize(task, instructions)
    @task = task
    @instructions = instructions
  end

  def process
    ActiveRecord::Base.transaction do
      JudgeAddressMotionToVacateTask.new(
        appeal: original_appeal,
        parent: original_task.parent,
        assigned_by: task.assigned_to,
        assigned_to: original_task.assigned_to,
        instructions: [instructions]
      ).save
      post_decision_motion.destroy!
      appeal.destroy!
    end
  end

  private

  def original_appeal
    @original_appeal ||= Appeal.original.find_by(stream_docket_number: appeal.docket_number)
  end

  def original_task
    @original_task ||= post_decision_motion.task
  end

  def post_decision_motion
    @post_decision_motion ||= PostDecisionMotion.find_by(appeal: appeal)
  end
end
