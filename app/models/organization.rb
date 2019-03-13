# frozen_string_literal: true

class Organization < ApplicationRecord
  has_one :vso_config, dependent: :destroy
  has_many :tasks, as: :assigned_to
  has_many :organizations_users, dependent: :destroy
  has_many :users, through: :organizations_users

  before_save :clean_url

  def admins
    organizations_users.includes(:user).select(&:admin?).map(&:user)
  end

  def non_admins
    organizations_users.reject(&:admin?).map(&:user)
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

  private

  def clean_url
    self.url = url&.parameterize&.dasherize
  end
end
