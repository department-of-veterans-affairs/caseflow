# frozen_string_literal: true

class InitialTasksFactory
  def initialize(appeal)
    @appeal = appeal
    @root_task = RootTask.find_or_create_by!(appeal: appeal)
  end

  def create_root_and_sub_tasks!
    create_vso_tracking_tasks
    create_subtasks! if appeal.Original?
  end

  private

  def create_vso_tracking_tasks
    @appeal.representatives.map do |rep|
      if TrackVeteranTask.where(appeal: @appeal, assigned_to: rep).empty?
        TrackVeteranTask.create!(appeal: @appeal, parent: @root_task, assigned_to: rep)
      end
    end
  end

  def create_subtasks!
    ActiveRecord::Base.transaction do
      distribution_task = DistributionTask.create!(appeal: @appeal, parent: @root_task)

      if @appeal.evidence_submission_docket?
        EvidenceSubmissionWindowTask.create!(appeal: @appeal, parent: distribution_task)
      elsif @appeal.hearing_docket?
        ScheduleHearingTask.create!(appeal: @appeal, parent: distribution_task)
      else
        vso_tasks = IhpTasksFactory.new(distribution_task).create_ihp_tasks!
        # If the appeal is direct docket and there are no ihp tasks,
        # then it is initially ready for distribution.
        distribution_task.ready_for_distribution! if vso_tasks.empty?
      end
    end
  end
end
