# frozen_string_literal: true

##
# Factory to create tasks for a new appeal based on appeal characteristics.

class InitialTasksFactory
  def initialize(appeal)
    @appeal = appeal
    @root_task = RootTask.find_or_create_by!(appeal: appeal)

    if @appeal.cavc?
      @cavc_remand = appeal.cavc_remand

      fail "CavcRemand required for CAVC-Remand appeal #{@appeal.id}" unless @cavc_remand
    end
  end

  def create_root_and_sub_tasks!
    create_vso_tracking_tasks
    ActiveRecord::Base.transaction do
      create_subtasks! if @appeal.original? || @appeal.cavc? || @appeal.appellant_substitution?
    end
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
    distribution_task # ensure distribution_task exists

    if @appeal.appellant_substitution?
      # copy task tree from source appeal
      source_appeal = @appeal.appellant_substitution.source_appeal
      copy_tasks
      # To-do create tasks based on appellant_substitution form
    elsif @appeal.cavc?
      create_cavc_subtasks
    elsif @appeal.evidence_submission_docket?
      EvidenceSubmissionWindowTask.create!(appeal: @appeal, parent: distribution_task)
    elsif @appeal.hearing_docket?
      ScheduleHearingTask.create!(appeal: @appeal, parent: distribution_task)
    elsif @appeal.direct_review_docket?
      vso_tasks = createIhpTask
      # If the appeal is direct docket and there are no ihp tasks,
      # then it is initially ready for distribution.
      distribution_task.ready_for_distribution! if vso_tasks.empty?
    else
      # Should never happen since all known docket types are checked above but let's fail just in case
      fail "Unhandled appeal docket type"
    end
  end

  def distribution_task
    @distribution_task ||= @appeal.tasks.open.find_by(type: :DistributionTask) ||
                           DistributionTask.create!(appeal: @appeal, parent: @root_task)
  end

  def createIhpTask
    # An InformalHearingPresentationTask is only created if 
    IhpTasksFactory.new(distribution_task).create_ihp_tasks!
  end

  def copy_tasks
    # Given a selection of task_ids, select it and all its tree ancestors
    # TODO for rspec: pull a real tree from prod that has a deep task tree and varied task types
    source_appeal = @appeal.appellant_substitution.source_appeal
    task_ids = @appeal.appellant_substitution.selected_task_ids

    # Order the tasks so they are created in the same order
    tasks = Task.where(id: task_ids).order(:id)

    fail "Could not find all the tasks" if (task_ids - tasks.pluck(:id)).any?

    fail "Expecting only tasks assigned to organizations" if tasks.map(&:assigned_to_type).include?("User")

    # TODO: ask if we want to shown a SubstitutionTask in the timeline, like DocketSwitch*Task
    
    evidence_submission_hold_end_date = Time.now + 20.days # @appeal.appellant_substitution.task_params
    new_tasks = tasks.map { |task|
      # TODO: set the ESW end_date
      if task.type == "EvidenceSubmissionWindowTask" && evidence_submission_hold_end_date
        EvidenceSubmissionWindowTask.create!(appeal: @appeal, parent: distribution_task, end_date: evidence_submission_hold_end_date)
      elsif task.type == "InformalHearingPresentationTask"
        vso_tasks = createIhpTask
        if @appeal.power_of_attorney.poa_participant_id != @appeal.appellant_substitution.poa_participant_id
          # If this happens, then the claimant's power_of_attorney is different than what is in BGS
          # and BGS probably needs to be updated.
          # TODO: warn_unexpected_state
          ihp_task = @appeal.tasks.open.find_by(type: :InformalHearingPresentationTask)
          # TO FIX: CAUTION: this is inefficient
          target_org = Representative.find_by(participant_id: @appeal.appellant_substitution.poa_participant_id)
          ihp_task&.update(assigned_to: target_org)
        end
        warn_unexpected_state if vso_tasks.blank?
        # binding.pry if vso_tasks.any?
      else
        task.copy_with_ancestors_to_stream(@appeal, extra_excluded_attributes: ["status"])
      end
    }
    # TODO: create TrackVeteranTask

    source_appeal.treee
    @appeal.reload.treee
    # binding.pry
  end

  def warn_unexpected_state
    # TODO: warn "Did not create user-selected InformalHearingPresentationTask b/c POA is not a Representative" 
    # TODO: use Raven to send sentry alert to #echo channel
    Rails.logger.warn("Did not create user-selected InformalHearingPresentationTask b/c POA is not a Representative: #{@appeal.appellant_substitution.poa_participant_id}")
  end

  # For AMA appeals. Create appropriate subtasks based on the CAVC Remand subtype
  def create_cavc_subtasks
    case @cavc_remand.cavc_decision_type
    when Constants.CAVC_DECISION_TYPES.remand
      create_remand_subtask
    when Constants.CAVC_DECISION_TYPES.straight_reversal, Constants.CAVC_DECISION_TYPES.death_dismissal
      if @cavc_remand.judgement_date.nil? || @cavc_remand.mandate_date.nil?
        cavc_task = CavcTask.create!(appeal: @appeal, parent: distribution_task)
        MandateHoldTask.create_with_hold(cavc_task)
      end
    else
      fail "Unsupported type: #{@cavc_remand.type}"
    end
  end

  def create_remand_subtask
    cavc_task = CavcTask.create!(appeal: @appeal, parent: distribution_task)
    case @cavc_remand.remand_subtype
    when Constants.CAVC_REMAND_SUBTYPES.mdr
      MdrTask.create_with_hold(cavc_task)
    when Constants.CAVC_REMAND_SUBTYPES.jmr, Constants.CAVC_REMAND_SUBTYPES.jmpr
      SendCavcRemandProcessedLetterTask.create!(appeal: @appeal, parent: cavc_task)
    else
      fail "Unsupported remand subtype: #{@cavc_remand.remand_subtype}"
    end
  end
end
