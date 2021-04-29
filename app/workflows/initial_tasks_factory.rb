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
      # create tasks based on appellant_substitution form
    elsif @appeal.cavc?
      create_cavc_subtasks
    elsif @appeal.evidence_submission_docket?
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

  def distribution_task
    @distribution_task ||= @appeal.tasks.open.find_by(type: :DistributionTask) ||
                           DistributionTask.create!(appeal: @appeal, parent: @root_task)
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
