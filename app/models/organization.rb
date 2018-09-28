class Organization < ApplicationRecord
  has_many :tasks, as: :assigned_to

  def self.assignable_hash
    where(type: nil).map { |o| { id: o.id, name: o.name } }
  end

  def user_has_access?(user)
    members.pluck(:id).include?(user.id)
  end

  def members
    @members ||= member_css_ids.map { |css_id| User.find_by(css_id: css_id) }.compact
  end

  def assignable_members_hash
    members.map { |m| { id: m.id, css_id: m.css_id, full_name: m.full_name } }
  end

  private

  def member_css_ids
    details = FeatureToggle.details_for(feature.to_sym)
    details && details[:users] || []
  end
end
