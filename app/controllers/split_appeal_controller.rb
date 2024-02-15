# frozen_string_literal: true

class SplitAppealController < ApplicationController
  protect_from_forgery with: :exception

  def split_appeal
    if FeatureToggle.enabled?(:split_appeal_workflow)
      # create transaction for split appeal validation
      Appeal.transaction do
        # Returns a 404 Not Found error if the appeal can not be found to be split
        begin
          Appeal.find(params[:appeal_id])
        rescue StandardError
          return render plain: "404 Not Found", status: :not_found
        end
        # process the split with params from payload
        process_split(params)
      end
    end
  end

  private

  def process_split(params)
    appeal = Appeal.find(params[:appeal_id])
    # set the appeal_split_process to true
    appeal.appeal_split_process = true
    # duplicate appeal
    dup_appeal = appeal.amoeba_dup
    # save the duplicate
    dup_appeal.save!
    create_split_task(appeal, params)
    # run extra duplicate methods to finish split
    dup_appeal.finalize_split_appeal(appeal, params)
    # set the appeal split process to false
    appeal.appeal_split_process = false
    dup_appeal.reload
    appeal.reload
    if FeatureToggle.enabled?(:specialty_case_team_distribution, user: RequestStore.store[:current_user])
      sct_parsing(appeal, dup_appeal)
    end
    render json: { split_appeal: dup_appeal, original_appeal: appeal }, status: :created
  end

  # TODO: Move logic to appeal model
  def sct_parsing(old_appeal, new_appeal)
    return unless old_appeal.has_distribution_task?

    old_sct_appeal = old_appeal.sct_appeal?
    new_sct_appeal = new_appeal.sct_appeal?
    both_sct_appeals = old_sct_appeal && new_sct_appeal
    was_in_sct_queue = old_appeal.tasks.any? { |t| t.type == SpecialtyCaseTeamAssignTask.name }

    if both_sct_appeals
      # We only need something here if we are blanking out the judge tasks. Otherwise a standard clone works
      # assign_appeal_to_the_specialty_case_team(new_appeal)
    elsif old_sct_appeal
      handle_old_sct_appeal(old_appeal, new_appeal, was_in_sct_queue)
    elsif new_sct_appeal
      handle_new_sct_appeal(old_appeal, new_appeal, was_in_sct_queue)
    end
  end

  def handle_old_sct_appeal(old_appeal, new_appeal, was_in_sct_queue)
    # If the old appeal was not in the sct queue, then it needs to be moved there and it was an old appeal before SCT
    move_appeal_back_to_distribution(new_appeal)
    unless was_in_sct_queue
      assign_appeal_to_the_specialty_case_team(old_appeal)
    end
  end

  def handle_new_sct_appeal(old_appeal, new_appeal, was_in_sct_queue)
    # If the old appeal was not in the sct queue, then it needs to be moved there and it was an old appeal before SCT
    move_appeal_back_to_distribution(old_appeal)
    unless was_in_sct_queue
      assign_appeal_to_the_specialty_case_team(new_appeal)
    end
  end

  # Probably move this logic to the appeal model or somewhere else
  def move_appeal_back_to_distribution(appeal)
    # Reopen the Distribution task
    distribution_task = appeal.tasks.find { |task| task.type == DistributionTask.name }
    # puts "found distribution_task"
    # puts distribution_task.inspect
    distribution_task.update!(status: "assigned", assigned_to: Bva.singleton, assigned_by: current_user)

    # puts "after updating the distribution task"
    # puts distribution_task.inspect
    # Cancel any open Judge, Attorney, or SpecialtyCaseTeam tasks
    cancelled_task_types = %w[SpecialtyCaseTeamAssignTask JudgeDecisionReviewTask JudgeAssignTask AttorneyTask]
    appeal.tasks.select { |task| cancelled_task_types.include?(task.type) }.each(&:cancel_task_and_child_subtasks)
    appeal.reload
    appeal
  end

  # This should be the same as Jonathan's method. Use the same way in both places
  def assign_appeal_to_the_specialty_case_team(appeal)
    remove_appeal_from_current_queue(appeal)
    SpecialtyCaseTeamAssignTask.find_or_create_by(
      appeal: appeal,
      parent: appeal.root_task,
      assigned_to: SpecialtyCaseTeam.singleton,
      assigned_by: current_user,
      status: Constants.TASK_STATUSES.assigned
    )
    appeal.reload
    appeal
  end

  # TODO: This should definitely be moved to the appeal model
  # TODO: Verify that this does not do bad things like cancelling tasks that are not supposed to be cancelled
  # Like open Hearing tasks or open mail tasks that might not be dependent on what queue the appeal is in
  def remove_appeal_from_current_queue(appeal)
    appeal.tasks.reject { |task| %w[RootTask DistributionTask].include?(task.type) }
      .each(&:cancel_task_and_child_subtasks)
  end

  def create_split_task(appeal, params)
    split_other_reason = params[:split_other_reason]
    split_reason = params[:split_reason]
    user_css_id = params[:user_css_id]

    split_user = User.find_by_css_id user_css_id
    instructions = if split_other_reason.strip.empty?
                     split_reason
                   else
                     split_other_reason
                   end
    Task.transaction do
      spt = SplitAppealTask.create!(
        appeal: appeal,
        parent: appeal.root_task,
        assigned_to: split_user,
        assigned_by: split_user,
        assigned_at: Time.zone.now
      )
      spt.instructions.push(instructions)
      spt.update!(status: Constants.TASK_STATUSES.completed)
    end
  end
end
