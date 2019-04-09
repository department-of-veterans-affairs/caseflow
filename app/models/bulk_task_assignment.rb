# frozen_string_literal: true

class BulkTaskAssignment
  include ActiveModel::Model

  validates :assigned_to_id, :organization_id, :task_type, presence: true
  validate :task_type_is_valid
  validate :assigned_to_exists
  validate :organization_exists

  attr_accessor :assigned_to_id, :organization_id, :task_type, :task_count

  def initialize(attributes = {})
    super

    @task_count ||= 0
  end

  def tasks_to_be_assigned
    task_type.constantize.active.where(assigned_to_id: organization_id).limit(task_count).order(:created_at)
  end

  def assigned_to
    @assigned_to ||= User.find_by(id: @assigned_to_id)
  end

  def organization
    @organization ||= Organization.find_by(id: @organization_id)
  end

  private

  def task_type_is_valid
    return if task_type.constantize
  rescue NameError
    errors.add(:task_type, "#{task_type} is not a valid task type")
  end

  def assigned_to_exists
    return if assigned_to

    errors.add(:assigned_to_id, "Could not find a User with id #{assigned_to_id}")
  end

  def organization_exists
    return if organization

    errors.add(:organization_id, "Could not find an Organization with id #{organization_id}")
  end
end
