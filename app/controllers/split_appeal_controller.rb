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

  # TODO: Move this logic down into the appeals model somehow so it doesn't suck as much
  def sct_parsing(old_appeal, new_appeal)
    # TODO: this should also be scoped to already distributed appeals
    # check both appeals for sct appeal tasks
    # TODO: The same thing should happen for both the old and new appeal
    if old_appeal.sct_appeal?
      # old_appeal.tasks.of_type(:SpecialtyCaseTeamAssignTask).first
      old_sct_task = old_appeal.tasks.find { |t| t.type == :SpecialtyCaseTeamAssignTask }
    end

    if old_appeal.sct_appeal? || !new_appeal.sct_appeal?
      # TODO: Possibly remove attorney task and decision review task
      # or cancel them before sending it back to distribution
      sct_task = new_appeal.tasks.find { |t| t.type == :SpecialtyCaseTeamAssignTask }
      sct_task&.cancelled!
      distribution_task = new_appeal.tasks.find { |t| t.type :DistributionTask }
      distribution_task.update(status: "assigned", assigned_to: Bva.singleton, assigned_by: current_user)
      distribution_task.save

    end
    # Just make sure everything is saved up and reloaded at the end
    old_appeal.save
    new_appeal.save
    old_appeal.reload
    new_appeal.reload
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
