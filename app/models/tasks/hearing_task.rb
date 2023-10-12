# frozen_string_literal: true

##
# A task used to track all related hearing subtasks.
# A hearing task is associated with a hearing record in Caseflow and might have several child tasks to resolve
# in order to schedule a hearing, hold it, and mark the disposition.
# If an appeal is in the Hearing docket, a HearingTask is automatically created as a child of DistributionTask.

class HearingTask < Task
  has_one :hearing_task_association
  delegate :hearing, to: :hearing_task_association, allow_nil: true
  before_validation :set_assignee

  class ExistingOpenHearingTaskOnAppeal < StandardError; end

  def self.label
    "All hearing-related tasks"
  end

  def default_instructions
    [COPY::HEARING_TASK_DEFAULT_INSTRUCTIONS]
  end

  ## Tag to determine if this task is considered a blocking task for Legacy Appeal Distribution
  def self.legacy_blocking?
    true
  end

  def cancel_and_recreate
    hearing_task = HearingTask.create!(
      appeal: appeal,
      parent: parent,
      assigned_to: Bva.singleton
    )

    cancel_task_and_child_subtasks

    hearing_task
  end

  def verify_org_task_unique
    true
  end

  def when_child_task_completed(child_task)
    # do not move forward to change location or create ihp if there are
    # other open hearing tasks
    if appeal.tasks.open.where(type: HearingTask.name).where.not(id: id).empty? && appeal.is_a?(Appeal)
      create_evidence_or_ihp_task
    end
    # super call must happen after AMA check to hold distribution,
    # but before the Legacy check to prevent premature location update.
    super
    if appeal.is_a?(LegacyAppeal)
      if FeatureToggle.enable!(:vlj_legacy_appeal)
        when_scm
      elsif appeal.tasks.open.where(type: HearingTask.name).empty?
        update_legacy_appeal_location
      end
    end
  end

  def when_scm
    if appeal.tasks.open.where(type: [HearingTask.name, ScheduleHearingTask.name]).empty?
      if !appeal.tasks.open.where(type: JudgeAssignTask.name).empty?
        process_appeal_scm
      else
        update_legacy_appeal_location
      end
    end
  end

  def process_appeal_scm
    current_judge_id = appeal.tasks.find_by(type: "JudgeAssignTask").assigned_to_id
    current_user = User.find(current_judge_id)
    update_legacy_appeal_location_scm(current_user.vacols_uniq_id)
  end

  def create_change_hearing_disposition_task(instructions = nil)
    task_names = [AssignHearingDispositionTask.name, ChangeHearingDispositionTask.name]
    active_disposition_tasks = children.open.where(type: task_names).to_a

    multi_transaction do
      ChangeHearingDispositionTask.create!(
        appeal: appeal,
        parent: self,
        instructions: instructions.present? ? [instructions] : nil
      )
      active_disposition_tasks.each { |task| task.update!(status: Constants.TASK_STATUSES.completed) }
    end
  end

  def disposition_task
    children.open.detect { |child| child.type == AssignHearingDispositionTask.name }
  end

  def unscheduled_hearing_notes
    last_version =
      versions.sort_by(&:created_at).reverse.detect do |version|
        version&.changeset&.keys&.include?("instructions")
      end

    {
      updated_at: last_version&.created_at,
      updated_by_css_id: User.find_by(id: last_version&.whodunnit)&.css_id,
      notes: instructions&.first
    }
  end

  def update_notes_as_instructions(notes)
    update!(instructions: [notes])
  end

  def update_from_params(params, current_user)
    payload_values = params.delete(:business_payloads)&.dig(:values)

    if payload_values&.include?(:notes)
      update_notes_as_instructions(payload_values&.[](:notes))

      [self] + children
    else
      super(params, current_user)
    end
  end

  private

  def update_legacy_appeal_location
    location = if hearing&.held?
                 LegacyAppeal::LOCATION_CODES[:transcription]
               elsif appeal.representative_is_colocated_vso?
                 LegacyAppeal::LOCATION_CODES[:service_organization]
               else
                 LegacyAppeal::LOCATION_CODES[:case_storage]
               end

    AppealRepository.update_location!(appeal, location)
  end

  def update_legacy_appeal_location_scm(current_judge)
    AppealRepository.update_location!(appeal, current_judge)
  end

  def create_evidence_or_ihp_task
    if hearing&.no_show?
      # if there was already a completed ESWT, set the appeal ready for distribution
      # More info in slack: https://dsva.slack.com/archives/C3EAF3Q15/p1617048776125000
      if children.closed.where(type: EvidenceSubmissionWindowTask.name).present?
        update!(status: Constants.TASK_STATUSES.completed)
      else
        EvidenceSubmissionWindowTask.create!(
          appeal: appeal,
          parent: self,
          assigned_to: MailTeam.singleton
        )
      end
    else
      IhpTasksFactory.new(parent).create_ihp_tasks!
    end
  end

  def cascade_closure_from_child_task?(_child_task)
    true
  end

  def set_assignee
    self.assigned_to = Bva.singleton
  end

  def update_status_if_children_tasks_are_closed(_child_task)
    if children.open.empty? && children.select do |child|
         child.type == AssignHearingDispositionTask.name && child.cancelled?
       end .any?
      return update!(status: :cancelled)
    end

    super
  end
end
