# frozen_string_literal: true

class CorrespondenceRootTaskFactory
  include TasksFactoryConcern

  def initialize(correspondence)
    @correspondence = correspondence
    @correspondence_task = CorrespondenceTask.find_or_create_by!(appeal_id: correspondence.id,
      assigned_to: Bva.singleton,
      appeal_type: "Correspondence",
      type: "CorrespondenceTask")

    @correspondence_task.update(status: "on_hold")


    @root_task = CorrespondenceRootTask.find_or_create_by!(appeal_id: correspondence.id,
      assigned_to: Bva.singleton,
      appeal_type: "Correspondence",
      parent_id: @correspondence_task.id,
      type: "CorrespondenceRootTask")

    @root_task.update(status: "on_hold")

  end

  def create_root_and_sub_tasks!
    ActiveRecord::Base.transaction do
      create_subtasks! if FeatureToggle.enabled?(:correspondence_queue)
    end
  end

  private

  def create_subtasks!
    review_package_task # ensure review_package_task exists
  end

  def review_package_task
    rpt ||= ReviewPackageTask.where(appeal_id: @correspondence.id, type: ReviewPackageTask.name)
    if rpt.blank?
      ReviewPackageTask.create!(
        appeal_id: @correspondence.id,
        parent_id: @root_task.id,
        assigned_to: MailTeam.singleton,
        appeal_type: Correspondence.name,
        type: ReviewPackageTask.name
      )
    end
  end
end
