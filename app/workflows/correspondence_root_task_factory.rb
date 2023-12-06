# frozen_string_literal: true

class CorrespondenceRootTaskFactory
  include TasksFactoryConcern

  def initialize(correspondence)
    @correspondence = correspondence
  end

  def create_root_and_sub_tasks!
    if FeatureToggle.enabled?(:correspondence_queue)
      ActiveRecord::Base.transaction do
        @root_task = CorrespondenceRootTask.create!(
          appeal_id: @correspondence.id,
          assigned_to: MailTeam.singleton,
          appeal_type: Correspondence.name,
          type: CorrespondenceRootTask.name
        )
        create_subtasks!
      end
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
