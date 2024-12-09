# frozen_string_literal: true

class SearchQueryService::QueriedAppeal < SimpleDelegator
  def initialize(attributes:, tasks_attributes:, hearings_attributes:)
    @attributes = OpenStruct.new(
      appeal: attributes,
      tasks: tasks_attributes,
      hearings: hearings_attributes,
      root_task: attributes.delete("root_task") || {},
      claimants: attributes.delete("claimants") || []
    )

    super(appeal)
  end

  def assigned_to_location
    return COPY::CASE_LIST_TABLE_POST_DECISION_LABEL if root_task&.status == Constants.TASK_STATUSES.completed

    return most_recently_updated_visible_task.assigned_to_label if most_recently_updated_visible_task

    # this condition is no longer needed since we only want active or on hold tasks
    return most_recently_updated_task&.assigned_to_label if most_recently_updated_task.present?

    fetch_api_status
  end

  def claimant_participant_ids
    claimants.map(&:participant_id)
  end

  def claimant
    claimants.max_by(&:id)
  end

  def claimants
    @claimants ||= begin
      attributes.claimants.map do |attrs|
        OpenStruct.new(attrs)
      end
    end
  end

  def root_task
    @root_task ||= begin
      if attributes.root_task.present?
        Task.new.tap do |task|
          task.assign_attributes attributes.root_task
        end
      end
    end
  end

  def advanced_on_docket_based_on_age?
    claimant&.date_of_birth.present? && Date.parse(claimant.date_of_birth) < 75.years.ago
  end

  def open_tasks
    @open_tasks ||= tasks.select do |task|
      Task.open_statuses.include?(task.status)
    end
  end

  def active?
    Task.active_statuses.include?(attributes.root_task["status"])
  end

  def pending_schedule_hearing_tasks
    open_tasks.select { |task| task.type == "ScheduleHearingTask" }
  end

  def evidence_submission_hold_pending_tasks
    open_tasks.select { |task| task.type == "EvidenceSubmissionWindowTask" }
  end

  def status
    BVAAppealStatus.new(
      tasks: BVAAppealStatus::Tasks.new(
        open: tasks.select(&:open?),
        active: tasks.select(&:active?),
        in_progress: tasks.select(&:in_progress?),
        cancelled: tasks.select(&:cancelled?),
        completed: tasks.select(&:completed?),
        assigned: tasks.select(&:assigned?)
      )
    ).status
  end

  private

  attr_reader :attributes

  def appeal
    @appeal ||= Appeal.new.tap do |appeal|
      appeal.assign_attributes(attributes.appeal)
    end
  end

  def most_recently_updated_visible_task
    visible_tasks.select { |task| Task.active_statuses.include?(task.status) }.max_by(&:updated_at) ||
      visible_tasks.select { |task| task.status == "on_hold" }.max_by(&:updated_at)
  end

  def visible_tasks
    @visible_tasks ||= tasks.reject do |task|
      Task.hidden_task_classes.include?(task.type)
    end
  end

  def most_recently_updated_task
    tasks.max_by(&:updated_at)
  end

  def tasks
    @tasks ||= begin
      attributes.tasks.map do |attrs|
        attrs["type"].constantize.new.tap do |task|
          task.assign_attributes attrs
        end
      end
    end
  end

  def fetch_api_status
    AppealStatusApiDecorator.new(
      self,
      scheduled_hearing
    ).fetch_status.to_s.titleize.to_sym
  end

  def scheduled_hearing
    @scheduled_hearing ||= begin
      hearings = attributes.hearings.map do |attrs|
        SearchQueryService::QueriedHearing.new(attrs)
      end

      hearings.reject(&:disposition).find do |hearing|
        hearing.scheduled_for >= Time.zone.today
      end
    end
  end
end
