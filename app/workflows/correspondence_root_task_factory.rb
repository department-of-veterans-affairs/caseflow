# frozen_string_literal: true

class CorrespondenceRootTaskFactory
  include TasksFactoryConcern

  def initialize(correspondence)
    @correspondence = correspondence
    @root_task = CorrespondenceRootTask.find_or_create_by!(appeal_id: correspondence.id,
      assigned_to: Bva.singleton,
      appeal_type: "Correspondence",
      type: "CorrespondenceRootTask")

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
    @review_package_task ||= ReviewPackageTask.where(appeal_id: @correspondence.id, appeal_type: ReviewPackageTask.name).any?
    ReviewPackageTask.create!(appeal: @correspondence, parent: @root_task, assigned_to: Bva.singleton) unless @review_package_task
  end
end
