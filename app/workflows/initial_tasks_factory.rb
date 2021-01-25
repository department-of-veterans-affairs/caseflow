# frozen_string_literal: true

##
# Factory to create tasks for a new appeal based on appeal characteristics.

class InitialTasksFactory
  def initialize(appeal, cavc_remand = nil)
    @appeal = appeal
    @root_task = RootTask.find_or_create_by!(appeal: appeal)

    if @appeal.cavc?
      @cavc_remand = cavc_remand
      @cavc_remand ||= appeal.cavc_remand

      fail "CavcRemand required for CAVC-Remand appeal #{@appeal.id}" unless @cavc_remand
    end
  end

  def create_root_and_sub_tasks!
    create_vso_tracking_tasks
    ActiveRecord::Base.transaction do
      create_subtasks! if @appeal.original? || @appeal.cavc?
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
    distribution_task = DistributionTask.create!(appeal: @appeal, parent: @root_task)

    if @appeal.cavc?
      create_cavc_subtasks(distribution_task)
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

  # For AMA appeals. Create appropriate subtasks based on the CAVC Remand subtype
  def create_cavc_subtasks(distribution_task)
    cavc_task = CavcTask.create!(appeal: @appeal, parent: distribution_task)

    if @cavc_remand.remand?
      if @cavc_remand.mdr?
        MdrTask.create_with_hold(cavc_task)
      elsif @cavc_remand.jmr? || @cavc_remand.jmpr?
        SendCavcRemandProcessedLetterTask.create!(appeal: @appeal, parent: cavc_task)
      else
        fail "Not yet supported remand subtype: #{@cavc_remand.remand_subtype}"
      end
    elsif @cavc_remand.straight_reversal? || @cavc_remand.death_dismissal?
      puts "TBD======"
    else
      fail "Not yet supported type: #{@cavc_remand.type}"
    end
  end
end
