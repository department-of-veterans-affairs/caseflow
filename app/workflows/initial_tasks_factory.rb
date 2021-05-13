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

  # rubocop:disable Metrics/CyclomaticComplexity
  def create_subtasks!
    distribution_task # ensure distribution_task exists

    if @appeal.appellant_substitution?
      create_selected_tasks
    elsif @appeal.cavc?
      create_cavc_subtasks
    elsif @appeal.veteran.date_of_death.present?
      distribution_task.ready_for_distribution!
    else
      case @appeal.docket_type
      when "evidence_submission"
        EvidenceSubmissionWindowTask.create!(appeal: @appeal, parent: distribution_task)
      when "hearing"
        ScheduleHearingTask.create!(appeal: @appeal, parent: distribution_task)
      when "direct_review"
        vso_tasks = create_ihp_task
        # If the appeal is direct docket and there are no ihp tasks,
        # then it is initially ready for distribution.
        distribution_task.ready_for_distribution! if vso_tasks.empty?
      else
        # Should never happen since all known docket types are checked above but let's fail just in case
        fail "Unhandled appeal docket type"
      end
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  def distribution_task
    @distribution_task ||= @appeal.tasks.open.find_by(type: :DistributionTask) ||
                           DistributionTask.create!(appeal: @appeal, parent: @root_task)
  end

  def create_ihp_task
    # An InformalHearingPresentationTask is only created if
    IhpTasksFactory.new(distribution_task).create_ihp_tasks!
  end

  def create_selected_tasks
    # Given a selection of task_ids, select it and all its tree ancestors
    task_ids = @appeal.appellant_substitution.selected_task_ids
    # Order the tasks so they are created in the same order
    source_tasks = Task.where(id: task_ids).order(:id)

    fail "Could not find all the tasks in the source appeal" if (task_ids - source_tasks.pluck(:id)).any?

    fail "Expecting only tasks assigned to organizations" if source_tasks.map(&:assigned_to_type).include?("User")

    source_tasks.map do |source_task|
      create_params = @appeal.appellant_substitution.task_params[source_task.id.to_s]
      create_task_from(source_task, create_params)
    end.flatten
  end

  def create_task_from(source_task, create_params)
    case source_task.type
    when "DistributionTask"
      distribution_task
    when "EvidenceSubmissionWindowTask"
      evidence_submission_hold_end_date = Time.find_zone("UTC").parse(create_params["hold_end_date"])
      EvidenceSubmissionWindowTask.create!(appeal: @appeal,
                                           parent: distribution_task,
                                           end_date: evidence_submission_hold_end_date)
    when "InformalHearingPresentationTask"
      vso_tasks = create_ihp_task
      warn_poa_not_a_representative if vso_tasks.blank?
      if @appeal.power_of_attorney.poa_participant_id != @appeal.appellant_substitution.poa_participant_id
        # To-do: Refine or replace this code block for unrecognized appellants.
        # If this happens, then the claimant's power_of_attorney is different than what is in BGS
        # and BGS probably needs to be updated.
        ihp_task = @appeal.tasks.open.find_by(type: :InformalHearingPresentationTask)
        target_org = Representative.find_by(participant_id: @appeal.appellant_substitution.poa_participant_id)
        ihp_task&.update(assigned_to: target_org)
        # To-do: close the other vso_tasks
      end
      vso_tasks
    else
      source_task.copy_with_ancestors_to_stream(@appeal, extra_excluded_attributes: ["status"])
    end
  end

  def warn_poa_not_a_representative
    msg = "Did not create user-selected InformalHearingPresentationTask because " \
      "POA is not a Representative: poa_participant_id = #{@appeal.appellant_substitution.poa_participant_id}"
    Raven.capture_message(msg)
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
