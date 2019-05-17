# frozen_string_literal: true

class BulkTaskAssignment
  include ActiveModel::Model

  validates :assigned_to_id, :organization_id, :task_type, presence: true
  validate :task_type_is_valid
  validate :assigned_to_exists
  validate :organization_exists
  # validate :assigned_to_part_of_organization
  # validate :assigned_by_part_of_organization

  attr_accessor :assigned_to_id, :assigned_by, :organization_id, :task_type, :task_count

  def initialize(attributes = {})
    super

    @task_count ||= 0
  end

  def process
    transaction do
      tasks_to_be_assigned.map do |task|
        assign_params = {
          assigned_to_type: "User",
          assigned_to_id: assigned_to.id
        }
        GenericTask.create_child_task(task, assigned_by, assign_params)
      end
    end
  end

  def tasks_to_be_assigned
    @tasks_to_be_assigned || = task_type.constantize
      .active.where(assigned_to_id: organization_id)
      .limit(task_count).order(:created_at)
  end

  def assigned_to
    @assigned_to ||= User.find_by(id: assigned_to_id)
  end

  def organization
    @organization ||= Organization.includes(:user).find_by(id: organization_id)
  end

  private

  def task_type_is_valid
    return if task_type.constantize
  rescue NameError
    errors.add(:task_type, "#{task_type} is not a valid task type")
  end

  def assigned_to_exists
    return if assigned_to

    errors.add(:assigned_to_id, "could not find a user with id #{assigned_to_id}")
  end

  def organization_exists
    return if organization

    errors.add(:organization_id, "could not find an organization with id #{organization_id}")
  end

  def assigned_to_part_of_organization
    return if organization && organization.users.include?(assigned_to)

    errors.add(:assigned_to, "does not belong to organization with id #{organization_id}")
  end

  def assigned_by_part_of_organization
    return if organization && organization.users.include?(assigned_by)

    errors.add(:assigned_by, "does not belong to organization with id #{organization_id}")
  end
end
