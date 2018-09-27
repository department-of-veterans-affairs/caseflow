class Organization < ApplicationRecord
  has_many :tasks, as: :assigned_to
  has_many :staff_field_for_organization

  def user_has_access?(user)
    members.pluck(:id).include?(user.id)
  end

  def members
    @members ||= member_css_ids.map { |css_id| User.find_by(css_id: css_id) }.compact
  end

  private

  def member_css_ids
    return [] unless staff_field_for_organization

    staff_records = VACOLS::Staff
    staff_field_for_organization.each do |sfo|
      staff_records = sfo.filter_staff_records(staff_records)
    end

    staff_records.pluck(:sdomainid)
  end
end
