# frozen_string_literal: true

class Organization < ApplicationRecord
  has_one :vso_config, dependent: :destroy
  has_many :tasks, as: :assigned_to
  has_many :organizations_users, dependent: :destroy
  has_many :users, through: :organizations_users
  has_many :non_admin_users, -> { non_admin }, class_name: "OrganizationsUser"

  validates :name, presence: true
  validates :url, presence: true, uniqueness: true

  before_save :clean_url

  def admins
    organizations_users.includes(:user).select(&:admin?).map(&:user)
  end

  def can_bulk_assign_tasks?
    false
  end

  def show_regional_office_in_queue?
    false
  end

  def show_reader_link_column?
    true
  end

  def use_task_pages_api?
    false
  end

  def non_admins
    organizations_users.includes(:user).non_admin.map(&:user)
  end

  def self.assignable(task)
    select { |org| org.can_receive_task?(task) }
  end

  def can_receive_task?(task)
    return false if task.assigned_to == self
    return false if task.assigned_to.is_a?(User) && task.parent && task.parent.assigned_to == self

    true
  end

  def next_assignee(_options = {})
    nil
  end

  def automatically_assign_to_member?
    !!next_assignee
  end

  def selectable_in_queue?
    true
  end

  def user_has_access?(user)
    users.pluck(:id).include?(user&.id)
  end

  def user_is_admin?(user)
    admins.include?(user)
  end

  def path
    "/organizations/#{url || id}"
  end

  def user_admin_path
    "#{path}/users"
  end

  def queue_tabs
    [
      unassigned_tasks_tab,
      assigned_tasks_tab,
      completed_tasks_tab
    ]
  end

  def unassigned_tasks_tab
    UnassignedTasksTab.new(
      assignee_name: name,
      show_regional_office_column: show_regional_office_in_queue?,
      show_reader_link_column: show_reader_link_column?,
      allow_bulk_assign: can_bulk_assign_tasks?
    ).to_hash
  end

  def assigned_tasks_tab
    AssignedTasksTab.new(assignee_name: name, show_regional_office_column: show_regional_office_in_queue?).to_hash
  end

  def completed_tasks_tab
    CompletedTasksTab.new(assignee_name: name, show_regional_office_column: show_regional_office_in_queue?).to_hash
  end

  def ama_task_serializer
    WorkQueue::TaskSerializer
  end

  private

  def clean_url
    self.url = url&.parameterize&.dasherize
  end
end
