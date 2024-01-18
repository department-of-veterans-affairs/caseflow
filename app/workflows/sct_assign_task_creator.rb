# frozen_string_literal: true

class SCTAssignTaskCreator
  def initialize(appeal:, assigned_by_id:)
    @appeal = appeal
    @assigned_by_id = assigned_by_id
  end

  def call
    # If an appeal does not have an open DistributionTask, then it has already been distributed by automatic
    # case distribution and a new SCTAssignTask should not be created. This should only occur if two users
    # request a distribution simultaneously. The check for LegacyAppeal was added for the Legacy DAS
    # deprecation code in app/workflows/das_deprecation/case_distribution
    return nil unless appeal.tasks.open.of_type(:DistributionTask).any? || appeal.is_a?(LegacyAppeal)

    Rails.logger.info("Assigning SCT task for appeal #{appeal.id}")
    task = reassign_or_create
    Rails.logger.info("Assigned SCT task with task id #{task.id} to #{task.assigned_to.css_id}")

    Rails.logger.info("Closing distribution task for appeal #{appeal.id} with task id #{task.id}")
    close_distribution_tasks_for_appeal if appeal.is_a?(Appeal)
    Rails.logger.info("Closed distribution task for appeal #{appeal.id}")

    task
  end

  private

  attr_reader :appeal, :judge

  def reassign_or_create
    open_sct_assign_task = @appeal.tasks.open.find_by_type(:SpecialtyCaseTeamAssignTask)

    return reassign_existing_open_task(open_sct_assign_task) if open_sct_assign_task

    SpecialtyCaseTeamAssignTask.create!(appeal: appeal,
                                        parent: appeal.root_task,
                                        assigned_to: SpecialtyCaseTeam.singleton)
  end

  def reassign_existing_open_task(open_sct_assign_task)
    begin
      assigning_user = @assigned_by_id.nil? ? nil : User.find(@assigned_by_id)
    rescue ActiveRecord::RecordNotFound
      Rails.logger.error("Could not locate a user with id #{@assigned_by_id} who reassigned a SCT assign task.")
      new_task, * = open_sct_assign_task.reassign({
                                                    assigned_to_type: :Organization,
                                                    assigned_to_id: SpecialtyCaseTeam.singleton.id,
                                                    appeal: appeal
                                                  }, nil)
      return new_task
    end
    new_task, * = open_sct_assign_task.reassign({
                                                  assigned_to_type: :Organization,
                                                  assigned_to_id: SpecialtyCaseTeam.singleton.id,
                                                  appeal: appeal
                                                }, assigning_user)
    new_task
  end

  def close_distribution_tasks_for_appeal
    appeal.tasks.of_type(:DistributionTask).update(status: :completed)
  end
end
