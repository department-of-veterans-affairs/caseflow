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
    {
      label: COPY::ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TAB_TITLE,
      name: Constants.QUEUE_CONFIG.UNASSIGNED_TASKS_TAB_NAME,
      description: format(COPY::ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TASKS_DESCRIPTION, name),
      # Compact to account for the maybe absent regional office column
      columns: [
        Constants.QUEUE_CONFIG.HEARING_BADGE_COLUMN,
        Constants.QUEUE_CONFIG.CASE_DETAILS_LINK_COLUMN,
        Constants.QUEUE_CONFIG.TASK_TYPE_COLUMN,
        show_regional_office_in_queue? ? Constants.QUEUE_CONFIG.REGIONAL_OFFICE_COLUMN : nil,
        Constants.QUEUE_CONFIG.APPEAL_TYPE_COLUMN,
        Constants.QUEUE_CONFIG.DOCKET_NUMBER_COLUMN,
        Constants.QUEUE_CONFIG.DAYS_ON_HOLD_COLUMN,
        is_a?(Representative) ? nil : Constants.QUEUE_CONFIG.DOCUMENT_COUNT_READER_LINK_COLUMN
      ].compact,
      allow_bulk_assign: can_bulk_assign_tasks?
    }
  end

  def assigned_tasks_tab
    {
      label: COPY::QUEUE_PAGE_ASSIGNED_TAB_TITLE,
      name: Constants.QUEUE_CONFIG.ASSIGNED_TASKS_TAB_NAME,
      description: format(COPY::ORGANIZATIONAL_QUEUE_PAGE_ASSIGNED_TASKS_DESCRIPTION, name),
      # Compact to account for the maybe absent regional office column
      columns: [
        Constants.QUEUE_CONFIG.HEARING_BADGE_COLUMN,
        Constants.QUEUE_CONFIG.CASE_DETAILS_LINK_COLUMN,
        Constants.QUEUE_CONFIG.TASK_TYPE_COLUMN,
        show_regional_office_in_queue? ? Constants.QUEUE_CONFIG.REGIONAL_OFFICE_COLUMN : nil,
        Constants.QUEUE_CONFIG.APPEAL_TYPE_COLUMN,
        Constants.QUEUE_CONFIG.TASK_ASSIGNEE_COLUMN,
        Constants.QUEUE_CONFIG.DOCKET_NUMBER_COLUMN,
        Constants.QUEUE_CONFIG.DAYS_ON_HOLD_COLUMN
      ].compact,
      allow_bulk_assign: false
    }
  end

  def completed_tasks_tab
    {
      label: COPY::QUEUE_PAGE_COMPLETE_TAB_TITLE,
      name: Constants.QUEUE_CONFIG.COMPLETED_TASKS_TAB_NAME,
      description: format(COPY::QUEUE_PAGE_COMPLETE_TASKS_DESCRIPTION, name),
      # Compact to account for the maybe absent regional office column
      columns: [
        Constants.QUEUE_CONFIG.HEARING_BADGE_COLUMN,
        Constants.QUEUE_CONFIG.CASE_DETAILS_LINK_COLUMN,
        Constants.QUEUE_CONFIG.TASK_TYPE_COLUMN,
        show_regional_office_in_queue? ? Constants.QUEUE_CONFIG.REGIONAL_OFFICE_COLUMN : nil,
        Constants.QUEUE_CONFIG.APPEAL_TYPE_COLUMN,
        Constants.QUEUE_CONFIG.TASK_ASSIGNEE_COLUMN,
        Constants.QUEUE_CONFIG.DOCKET_NUMBER_COLUMN,
        Constants.QUEUE_CONFIG.DAYS_ON_HOLD_COLUMN
      ].compact,
      allow_bulk_assign: false
    }
  end

  def ama_task_serializer
    WorkQueue::TaskSerializer
  end

  private

  def clean_url
    self.url = url&.parameterize&.dasherize
  end
end
