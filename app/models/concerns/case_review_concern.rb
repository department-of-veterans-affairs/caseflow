# frozen_string_literal: true

module CaseReviewConcern
  extend ActiveSupport::Concern

  # belongs_to :appeal, polymorphic: true

  attr_accessor :issues

  included do
    validates :task, presence: true, unless: :legacy?
  end

  def appeal_through_task
    @appeal ||= if legacy?
                  LegacyAppeal.find_or_create_by(vacols_id: vacols_id)
                else
                  Task.find(task_id).appeal
                end
  end

  private

  def legacy?
    (task_id =~ LegacyTask::TASK_ID_REGEX) ? true : false
  end

  def vacols_id
    task_id&.split("-", 2)&.first
  end

  def created_in_vacols_date
    task_id&.split("-", 2)&.second&.to_date
  end
end
