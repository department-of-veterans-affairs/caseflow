# frozen_string_literal: true

class Organization < CaseflowRecord
  has_one :vso_config, dependent: :destroy
  has_many :tasks, as: :assigned_to
  has_many :organizations_users, dependent: :destroy
  has_many :users, through: :organizations_users
  has_many :non_admin_users, -> { non_admin }, class_name: "OrganizationsUser"
  require_dependency "dvc_team"

  validates :name, presence: true
  validates :url, presence: true, uniqueness: true

  before_save :clean_url

  enum status: {
    Constants.ORGANIZATION_STATUSES.active.to_sym => Constants.ORGANIZATION_STATUSES.active,
    Constants.ORGANIZATION_STATUSES.inactive.to_sym => Constants.ORGANIZATION_STATUSES.inactive
  }

  default_scope { active }

  class << self
    def assignable(task)
      select { |org| org.can_receive_task?(task) }
    end

    def find_by_name_or_url(string)
      find_by(name: string) || find_by(url: string)
    end

    def default_active_tab
      Constants.QUEUE_CONFIG.UNASSIGNED_TASKS_TAB_NAME
    end
  end

  def active!
    self.status_updated_at = Time.zone.now
    super
  end

  def inactive!
    self.status_updated_at = Time.zone.now
    super
  end

  def users_can_create_mail_task?
    false
  end

  def show_regional_office_in_queue?
    false
  end

  def show_reader_link_column?
    true
  end

  def use_task_pages_api?
    true
  end

  def add_user(user)
    OrganizationsUser.find_or_create_by!(organization: self, user: user)
  end

  def admins
    organizations_users.includes(:user).admin.map(&:user)
  end

  def non_admins
    organizations_users.includes(:user).non_admin.map(&:user)
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
      on_hold_tasks_tab,
      completed_tasks_tab
    ]
  end

  def unassigned_tasks_tab
    ::OrganizationUnassignedTasksTab.new(
      assignee: self,
      show_regional_office_column: show_regional_office_in_queue?,
      show_reader_link_column: show_reader_link_column?
    )
  end

  def assigned_tasks_tab
    ::OrganizationAssignedTasksTab.new(assignee: self, show_regional_office_column: show_regional_office_in_queue?)
  end

  def on_hold_tasks_tab
    ::OrganizationOnHoldTasksTab.new(assignee: self, show_regional_office_column: show_regional_office_in_queue?)
  end

  def completed_tasks_tab
    ::OrganizationCompletedTasksTab.new(assignee: self, show_regional_office_column: show_regional_office_in_queue?)
  end

  def serialize
    {
      accepts_priority_pushed_cases: accepts_priority_pushed_cases,
      id: id,
      name: name,
      participant_id: participant_id,
      type: type,
      url: url,
      user_admin_path: user_admin_path
    }
  end

  private

  def clean_url
    self.url = url&.parameterize&.dasherize
  end
end
