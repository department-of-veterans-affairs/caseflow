# frozen_string_literal: true

class ChangeHearingRequestTypeTaskFactory
  def initialize(parent)
    @parent = parent
  end

  def create_change_hearing_request_type_tasks!
    appeal = @parent.appeal
    appeal.representatives.select { |org| org.should_change_hearing_request_type?(appeal) }.map do |vso_organization|
      existing_task = ChangeHearingRequestTypeTask.find_by(
        appeal: appeal,
        assigned_to: vso_organization
      )
      existing_task || ChangeHearingRequestTypeTask.create!(
        appeal: appeal,
        parent: @parent,
        assigned_to: vso_organization
      )
    end
  end
end
