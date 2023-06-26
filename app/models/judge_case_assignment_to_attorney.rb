# frozen_string_literal: true

class JudgeCaseAssignmentToAttorney
  include ActiveModel::Model

  attr_accessor :appeal_id, :assigned_to, :task_id, :assigned_by, :judge

  validates :assigned_by, :assigned_to, presence: true
  # validates :task_id, format: { with: /\A[0-9A-Z]+-[0-9]{4}-[0-9]{2}-[0-9]{2}\Z/i }, allow_blank: true
  validate :assigned_by_role_is_valid

  def assign_to_attorney!
    MetricsService.record("VACOLS: assign_case_to_attorney #{vacols_id}",
                          service: :vacols,
                          name: "assign_case_to_attorney") do
      self.class.repository.assign_case_to_attorney!(
        assigned_by: assigned_by,
        judge: judge || assigned_by,
        attorney: assigned_to,
        vacols_id: vacols_id
      )
    end
  end

  def reassign_to_attorney!
    MetricsService.record("VACOLS: reassign_case_to_attorney #{vacols_id}",
                          service: :vacols,
                          name: "reassign_case_to_attorney") do
      self.class.repository.reassign_case_to_attorney!(
        judge: assigned_by,
        attorney: assigned_to,
        vacols_id: vacols_id,
        created_in_vacols_date: created_in_vacols_date
      )
    end
  end

  def created_in_vacols_date
    task_id&.split("-", 2)&.second&.to_date
  end

  def vacols_id
    vacols_id_from_task_id || LegacyAppeal.find(appeal_id).vacols_id
  end

  def last_case_assignment
    VACOLS::CaseAssignment.latest_task_for_appeal(vacols_id)
  end

  private

  def vacols_id_from_task_id
    task_id&.split("-", 2)&.first
  end

  def assigned_by_role_is_valid
    if assigned_by && !(assigned_by.judge_in_vacols? || assigned_by.can_act_on_behalf_of_judges?)
      errors.add(:assigned_by, "has to be a judge or a SpecialCaseMovementTeam member")
    end
  end

  class << self
    def create(task_attrs)
      task = new(task_attrs)
      task.assign_to_attorney! if task.valid?
      task
    end

    def update(task_attrs)
      task = new(task_attrs)
      task.reassign_to_attorney! if task.valid?
      task
    end

    def repository
      QueueRepository
    end
  end
end
