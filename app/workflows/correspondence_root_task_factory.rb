# frozen_string_literal: true

class CorrespondenceRootTaskFactory
  include TasksFactoryConcern

  def initialize(correspondence)
    @correspondence = correspondence
    @root_task = CorrespondenceRootTask.find_or_create_by!(correspondence: correspondence, assigned_to: Bva.singleton)
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
    @review_package_task ||= @correspondence.tasks.open.find_by(type: :ReviewPackageTask) ||
    ReviewPackageTask.create!(correspondence: @correspondence, parent: @root_task)
  end

end
