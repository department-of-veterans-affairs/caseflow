# frozen_string_literal: true

class BulkTaskAssignment
  include ActiveModel::Model

  validates :assigned_to_id, :organization_id, :task_type, presence: true
  validate :task_type_is_valid
  validate :assigned_to_exists
  validate :organization_exists
  validate :regional_office_is_valid
  validate :assigned_to_part_of_organization
  validate :assigned_by_part_of_organization
  validate :organization_can_bulk_assign

  attr_accessor :assigned_to_id, :assigned_by, :organization_id, :task_type, :regional_office, :task_count

  def initialize(attributes = {})
    super

    @task_count ||= 0
  end

  def process
    ActiveRecord::Base.transaction do
      tasks_to_be_assigned.map do |task|
        Task.create!(
          type: task_type,
          appeal: task.appeal,
          assigned_by: assigned_by,
          parent: task,
          assigned_to: assigned_to
        )
      end
    end
  end

  private

  def tasks_to_be_assigned
    @tasks_to_be_assigned ||= begin
      tasks = task_type.constantize
        .active.where(assigned_to_id: organization_id)
        .limit(task_count).order(:created_at)
      if regional_office
        tasks = tasks.joins(
          "INNER JOIN appeals ON appeals.id = appeal_id AND tasks.appeal_type = 'Appeal'"
        ).where("appeals.closest_regional_office = ?", regional_office)
      end
      tasks
    end
  end

  def assigned_to
    @assigned_to ||= User.find_by(id: assigned_to_id)
  end

  def organization
    @organization ||= Organization.includes(:users).find_by(id: organization_id)
  end

  def task_type_is_valid
    return if task_type.constantize
  rescue NameError
    errors.add(:task_type, "#{task_type} is not a valid task type")
  end

  def assigned_to_exists
    return if assigned_to

    errors.add(:assigned_to_id, "could not find a user with id #{assigned_to_id}")
  end

  def regional_office_is_valid
    return unless regional_office

    RegionalOffice.find!(regional_office)
  rescue RegionalOffice::NotFoundError
    errors.add(:regional_office, "could not find regional office: #{regional_office}")
  end

  def organization_exists
    return if organization

    errors.add(:organization_id, "could not find an organization with id #{organization_id}")
  end

  def assigned_to_part_of_organization
    return if organization&.users&.include?(assigned_to)

    errors.add(:assigned_to, "does not belong to organization with id #{organization_id}")
  end

  def assigned_by_part_of_organization
    return if organization&.users&.include?(assigned_by)

    errors.add(:assigned_by, "does not belong to organization with id #{organization_id}")
  end

  def organization_can_bulk_assign
    return if organization&.can_bulk_assign_tasks?

    errors.add(:organization, "with id #{organization_id} cannot bulk assign tasks")
  end
end
