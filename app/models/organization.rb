class Organization < ApplicationRecord
  has_many :tasks, as: :assigned_to

  def user_has_access?(user)
    members.pluck(:id).include?(user.id)
  end

  def members
    @members ||= member_css_ids.map { |css_id| User.find_by(css_id: css_id) }.compact
  end

  private

  def member_css_ids
    return [] unless staff_field_for_organization
    VACOLS::Staff.where("#{staff_field_for_organization.name}": staff_field_for_organization.values).pluck(:sdomainid)
  end
end
