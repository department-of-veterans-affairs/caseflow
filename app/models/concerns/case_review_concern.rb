# frozen_string_literal: true

module CaseReviewConcern
  extend ActiveSupport::Concern

  attr_accessor :issues

  included do
    include BelongsToPolymorphicAppealConcern
    belongs_to_polymorphic_appeal :appeal

    validates :task, presence: true, unless: :legacy?
  end

  def appeal
    # This associate_with_appeal call can be removed once all DB records have appeal_* values and
    # code has been updated to populate them on creation of all CaseReview records.
    associate_with_appeal unless appeal_association?

    # use the `belongs_to :appeal` association
    super
  end

  def associate_with_appeal
    # Populate appeal_* column values based on original implementation that uses `task_id`
    update_attributes(
      appeal_id: appeal_through_task_id&.id,
      appeal_type: appeal_through_task_id&.class&.name
    )
  end

  def appeal_through_task_id
    @appeal_through_task_id ||= if legacy?
                                  LegacyAppeal.find_or_create_by(vacols_id: vacols_id)
                                else
                                  Task.find(task_id).appeal
                                end
  end

  def legacy?
    # use column values if they exist
    return appeal.is_a?(LegacyAppeal) if appeal_association?

    return task.appeal.is_a?(LegacyAppeal) if task && task.appeal

    # fall back to original implementation
    (task_id =~ LegacyTask::TASK_ID_REGEX) ? true : false
  end

  # This is actually the appeal's vacols_id, rather than the id for some Case Review record in VACOLS.
  # Although there is this LegacyAppeal#vacols_case_review.
  def vacols_id
    # use column values if they exist
    return appeal.vacols_id if appeal_association?
    return task.appeal.vacols_id if task && task.appeal&.is_a?(LegacyAppeal)

    # fall back to original implementation
    task_id&.split("-", 2)&.first
  end

  def created_in_vacols_date
    task_id&.split("-", 2)&.second&.to_date
  end

  private

  def appeal_association?
    appeal_id && appeal_type
  end
end
