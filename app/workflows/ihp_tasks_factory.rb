# frozen_string_literal: true

class IhpTasksFactory
  prepend IhpTaskPending

  def initialize(parent)
    @parent = parent
  end

  def create_ihp_tasks!
    appeal = @parent.appeal

    if appeal.status.send(:open_pre_docket_task?)
      cancel_any_existing_ihp_tasks(appeal)
      return []
    end

    appeal.representatives.select { |org| org.should_write_ihp?(appeal) }.map do |vso_organization|
      # For some RAMP appeals, this method may run twice.
      existing_task = InformalHearingPresentationTask.find_by(
        appeal: appeal,
        assigned_to: vso_organization
      )
      existing_task || InformalHearingPresentationTask.create!(
        appeal: appeal,
        parent: @parent,
        assigned_to: vso_organization
      )
    end
  end

  private

  def cancel_any_existing_ihp_tasks(appeal)
    appeal.representatives.select { |org| org.should_write_ihp?(appeal) }.each do |vso_organization|
      existing_task = InformalHearingPresentationTask.find_by(
        appeal: appeal,
        assigned_to: vso_organization
      )
      existing_task&.update!(status: Constants.TASK_STATUSES.cancelled)
    end
  end
end
