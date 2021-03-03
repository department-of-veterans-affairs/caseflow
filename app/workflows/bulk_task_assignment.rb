# frozen_string_literal: true

# Assign multiple cases, which are selected based on parameters.
# Cases are prioritized in the following order:
#   - CAVC AOD Cases
#   - AOD Cases
#   - CAVC Cases
#   - remaining cases
class BulkTaskAssignment
  include ActiveModel::Model

  validates :assigned_to_id, :organization_url, :task_type, presence: true
  validate :task_type_is_valid
  validate :assigned_to_exists
  validate :organization_exists
  validate :regional_office_is_valid
  validate :assigned_to_part_of_organization
  validate :assigned_by_admin_of_organization

  attr_accessor :assigned_to_id, :assigned_by, :organization_url, :task_type, :regional_office, :task_count

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
          instructions: task.instructions,
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
      tasks = task_type.constantize.active
        .where(assigned_to_id: organization.id)
        .limit(task_count)
        .with_cached_appeals.order(Task.order_by_appeal_priority_clause)
      if regional_office
        tasks = tasks.joins("INNER JOIN appeals ON appeals.id = #{Task.table_name}.appeal_id "\
                      "AND #{Task.table_name}.appeal_type = '#{Appeal.name}'")
          .where("closest_regional_office = ?", regional_office) +
                tasks.joins("INNER JOIN legacy_appeals ON legacy_appeals.id = #{Task.table_name}.appeal_id "\
                      "AND #{Task.table_name}.appeal_type = '#{LegacyAppeal.name}'")
          .where("closest_regional_office = ?", regional_office)
      end
      tasks
    end
  end

  def assigned_to
    @assigned_to ||= User.find_by(id: assigned_to_id)
  end

  def organization
    @organization ||= Organization.includes(:users).find_by(url: organization_url)
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

    errors.add(:organization_url, "could not find an organization with url #{organization_url}")
  end

  def assigned_to_part_of_organization
    return if organization&.users&.include?(assigned_to)

    errors.add(:assigned_to, "does not belong to organization with url #{organization_url}")
  end

  def assigned_by_admin_of_organization
    return if organization&.admins&.include?(assigned_by)

    errors.add(:assigned_by, "is not admin of organization with url #{organization_url}")
  end
end
