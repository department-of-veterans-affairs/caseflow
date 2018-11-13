class Organization < ApplicationRecord
  has_many :tasks, as: :assigned_to
  has_many :organizations_users, dependent: :destroy
  has_many :users, through: :organizations_users

  def self.assignable(task)
    organizations = where(type: [nil, BvaDispatch.name])

    # Exclude the current organization from the list of assignable organizations if the
    # task is assigned to this organization or the task is a child of a task assigned to
    # this organization. Prevents assignment loops.
    if task.assigned_to_type == name
      organizations.where.not(id: task.assigned_to_id)
    elsif task.assigned_to_type == User.name && task.parent && task.parent.assigned_to_type == name
      organizations.where.not(id: task.parent.assigned_to_id)
    else
      organizations
    end
  end

  def user_has_access?(user)
    users.pluck(:id).include?(user.id)
  end
end
