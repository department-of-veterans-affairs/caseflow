class Organization < ApplicationRecord
  has_many :tasks, as: :assigned_to
  has_many :organizations_users, dependent: :destroy
  has_many :users, through: :organizations_users

  def admins
    organizations_users.select(&:admin?).map(&:user)
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

  def user_has_access?(user)
    users.pluck(:id).include?(user.id)
  end

  def user_is_admin?(user)
    organizations_users.where(admin: true).pluck(:user_id).include?(user.id)
  end

  def path
    "/organizations/#{url ? url : id}"
  end

  def user_admin_path
    "#{path}/users"
  end
end
