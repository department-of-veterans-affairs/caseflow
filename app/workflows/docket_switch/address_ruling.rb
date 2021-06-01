# frozen_string_literal: true

##
# The DocketSwitch::AddressRuling handles creating a Granted or Deny task subtree under the Ruling task.

class DocketSwitch::AddressRuling
  attr_reader :ruling_task, :new_task_type, :assigned_by, :assigned_to, :instructions

  delegate :appeal, to: :ruling_task

  def initialize(ruling_task:, new_task_type:, assigned_by:, assigned_to:, instructions:)
    @ruling_task = ruling_task
    @new_task_type = new_task_type.constantize
    @assigned_by = assigned_by
    @assigned_to = assigned_to
    @instructions = instructions
  end

  def process!
    ActiveRecord::Base.transaction do
      cotb_task = create_task!(parent_task: ruling_task, assigned_to: ClerkOfTheBoard.singleton)
      create_task!(parent_task: cotb_task, assigned_to: assigned_to)
    end
  end

  private

  def create_task!(parent_task:, assigned_to:)
    new_task_type.create!(
      appeal: appeal,
      parent: parent_task,
      assigned_by: assigned_by,
      assigned_to: assigned_to,
      instructions: [instructions]
    )
  end
end
