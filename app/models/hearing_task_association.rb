# frozen_string_literal: true

class HearingTaskAssociation < CaseflowRecord
  belongs_to :hearing_task
  belongs_to :hearing, polymorphic: true

  validate :hearing_has_one_active_hearing_task

  private

  def hearing_has_one_active_hearing_task
    return if HearingTaskAssociation
      .includes(:hearing_task)
      .where(hearing_id: hearing_id, hearing_type: hearing_type)
      .where("tasks.status NOT IN (?)", Task.closed_statuses)
      .references(:hearing_task)
      .empty?

    errors.add(
      :hearing_task,
      format(
        COPY::HEARING_TASK_ASSOCIATION_NOT_UNIQUE_MESSAGE,
        hearing_type,
        hearing_id
      )
    )
  end
end
