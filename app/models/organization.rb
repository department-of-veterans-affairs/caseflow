class Organization < ApplicationRecord
  has_many :tasks, as: :assigned_to
  has_many :staff_field_for_organization

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
    members.pluck(:id).include?(user.id)
  end

  def members
    @members ||= User.where(css_id: member_css_ids.uniq)
  end

  private

  def member_css_ids
    return [] unless staff_field_for_organization.length > 0

    staff_records = VACOLS::Staff.where(sactive: "A")
    staff_field_for_organization.each do |sfo|
      staff_records = sfo.filter_staff_records(staff_records)
    end

    staff_records.pluck(:sdomainid)
  end
end
