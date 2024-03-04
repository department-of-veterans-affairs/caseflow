# frozen_string_literal: true

##
# Factory to create tasks for a new appeal based on appeal characteristics.

class InitialTasksFactory
  include TasksFactoryConcern

  def initialize(appeal)
    @appeal = appeal
    @root_task = RootTask.find_or_create_by!(appeal: appeal)

    if @appeal.cavc?
      @cavc_remand = appeal.cavc_remand

      fail "CavcRemand required for CAVC-Remand appeal #{@appeal.id}" unless @cavc_remand
    end
  end

  delegate :veteran, to: :@appeal

  STATE_CODES_REQUIRING_TRANSLATION_TASK = %w[VI VQ PR PH RP PI].freeze

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def create_root_and_sub_tasks!
    # if changes to mst or pact, create IssueUpdateTask
    if (@appeal.mst? && FeatureToggle.enabled?(:mst_identification, user: RequestStore[:current_user])) ||
       (@appeal.pact? && FeatureToggle.enabled?(:pact_identification, user: RequestStore[:current_user]))
      create_establishment_task
    end
    create_vso_tracking_tasks
    ActiveRecord::Base.transaction do
      create_subtasks! if @appeal.original? || @appeal.cavc? || @appeal.appellant_substitution?
      if @appeal.contested_claim? && FeatureToggle.enabled?(:cc_appeal_workflow)
        send_initial_notification_letter
      end
    end
    maybe_create_translation_task
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

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
    elsif should_streamline_death_dismissal?
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
      end
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  def distribution_task
    @distribution_task ||= @appeal.tasks.open.find_by(type: :DistributionTask) ||
                           DistributionTask.create!(appeal: @appeal, parent: @root_task)
  end

  def send_initial_notification_letter
    # depending on the docket type, create cooresponding task as parent task
    case @appeal.docket_type
    when "evidence_submission"
      parent_task = @appeal.tasks.find_by(type: "EvidenceSubmissionWindowTask")
    when "hearing"
      parent_task = @appeal.tasks.find_by(type: "ScheduleHearingTask")
    when "direct_review"
      parent_task = distribution_task
    end
    unless parent_task.nil?
      @send_initial_notification_letter ||= @appeal.tasks.open.find_by(type: :SendInitialNotificationLetterTask) ||
                                            SendInitialNotificationLetterTask.create!(
                                              appeal: @appeal,
                                              parent: parent_task,
                                              assigned_to: Organization.find_by_url("clerk-of-the-board"),
                                              assigned_by: RequestStore[:current_user]
                                            )
    end
  end

  def create_ihp_task
    # An InformalHearingPresentationTask is only created for `appeal.representatives` who `should_write_ihp?``
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
      creation_params = @appeal.appellant_substitution.task_params[source_task.id.to_s]
      create_task_from(source_task, creation_params)
    end.flatten
  end

  def create_task_from(source_task, creation_params)
    case source_task.type
    when "DistributionTask"
      distribution_task
    when "EvidenceSubmissionWindowTask"
      create_evidence_submission_window_task(@appeal, source_task, creation_params)
    when "InformalHearingPresentationTask"
      handle_substitution_ihp_task_and_poa
    when "ScheduleHearingTask"
      ScheduleHearingTask.create!(appeal: @appeal, parent: distribution_task)
    else
      excluded_attrs = %w[status closed_at placed_on_hold_at]
      source_task.copy_with_ancestors_to_stream(@appeal, extra_excluded_attributes: excluded_attrs)
    end
  end

  def handle_substitution_ihp_task_and_poa
    create_ihp_task.tap do |vso_tasks|
      warn_poa_not_a_representative if vso_tasks.blank?
      if @appeal.power_of_attorney.poa_participant_id != @appeal.appellant_substitution.poa_participant_id
        handle_different_poa
      end
    end
  end

  def warn_poa_not_a_representative
    msg = "For Appeal #{@appeal.id}, did not create user-selected InformalHearingPresentationTask because " \
      "POA is not a Representative: poa_participant_id = #{@appeal.appellant_substitution.poa_participant_id}"
    # Change this to a Rails.logger.warning(msg) if Sentry becomes too noisy
    Raven.capture_message(msg)
  end

  def handle_different_poa
    # To-do: Refine or replace this code block for unrecognized appellants.
    # If this happens, then the claimant's power_of_attorney is different than what is in BGS
    # and BGS probably needs to be updated.
    # ihp_task = @appeal.tasks.open.find_by(type: :InformalHearingPresentationTask)
    # target_org = Representative.find_by(participant_id: @appeal.appellant_substitution.poa_participant_id)
    # ihp_task&.update(assigned_to: target_org)
    # To-do: close the other vso_tasks
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
    when Constants.CAVC_REMAND_SUBTYPES.jmr, Constants.CAVC_REMAND_SUBTYPES.jmpr,
      Constants.CAVC_REMAND_SUBTYPES.jmr_jmpr
      SendCavcRemandProcessedLetterTask.create!(appeal: @appeal, parent: cavc_task)
    else
      fail "Unsupported remand subtype: #{@cavc_remand.remand_subtype}"
    end
  end

  def should_streamline_death_dismissal?
    return false if @appeal.appellant_is_not_veteran
    return false if @appeal.veteran.alive?

    FeatureToggle.enabled?(:death_dismissal_streamlining)
  end

  def maybe_create_translation_task
    veteran_state_code = veteran&.state
    va_dot_gov_address = veteran&.validate_address
    state_code = va_dot_gov_address&.dig(:state_code) || veteran_state_code
  rescue Caseflow::Error::VaDotGovAPIError
    state_code = veteran_state_code
  ensure
    TranslationTask.create_from_parent(distribution_task) if STATE_CODES_REQUIRING_TRANSLATION_TASK.include?(state_code)
  end

  def create_establishment_task
    task = EstablishmentTask.create!(
      appeal: @appeal,
      parent: @root_task,
      assigned_by: RequestStore[:current_user],
      assigned_to: SpecialIssueEditTeam.singleton,
      completed_by: RequestStore[:current_user]
    )
    task.format_instructions(@appeal.request_issues)
    task.completed!
  end
end
