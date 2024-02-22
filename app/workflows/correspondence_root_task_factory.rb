# frozen_string_literal: true

class CorrespondenceRootTaskFactory
  include TasksFactoryConcern

  def initialize(correspondence)
    @correspondence = correspondence
  end

  def create_root_and_sub_tasks!
    ActiveRecord::Base.transaction do
      create_root!
      create_subtasks!
    end
  end

  private

  def create_root!
    @correspondence_task = CorrespondenceTask.find_or_create_by!(
      appeal_id: @correspondence.id,
      assigned_to: InboundOpsTeam.singleton,
      appeal_type: "Correspondence",
      type: "CorrespondenceTask"
    )

    @correspondence_task.update(status: "on_hold")

    @root_task = CorrespondenceRootTask.find_or_create_by!(
      appeal_id: @correspondence.id,
      assigned_to: InboundOpsTeam.singleton,
      appeal_type: "Correspondence",
      parent_id: @correspondence_task.id,
      type: "CorrespondenceRootTask"
    )

    @root_task.update(status: "on_hold")
  end

  def create_subtasks!
    @review_package_task = ReviewPackageTask.find_or_create_by!(
      appeal_id: @correspondence.id,
      assigned_to: InboundOpsTeam.singleton,
      appeal_type: "Correspondence",
      parent_id: @root_task.id,
      type: "ReviewPackageTask"
    )
  end
end
