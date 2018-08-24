class Organization < ApplicationRecord
  has_many :tasks, as: :assigned_to

  def user_has_access?(user)
    members.pluck(:id).include?(user.id)
  end

  def members
    @members ||= member_css_ids.map { |css_id| User.find_by(css_id: css_id) }
  end

  private

  def member_css_ids
    FeatureToggle.details_for(feature.to_sym)[:users]
  end
end
