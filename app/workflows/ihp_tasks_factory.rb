# frozen_string_literal: true

class IhpTasksFactory
  def initialize(parent)
    @parent = parent
  end

  def create_ihp_tasks!
    appeal = @parent.appeal

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
end
