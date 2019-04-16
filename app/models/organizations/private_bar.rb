# frozen_string_literal: true

class PrivateBar < Representative
  def self.for_user(user)
    user.organizations.detect { |org| org.is_a?(self) }
  end

  def self.create_for_user(user)
    create!(name: user.full_name, url: user.css_id.downcase, participant_id: user.participant_id).tap do |org|
      OrganizationsUser.add_user_to_organization(user, org)
    end
  end
end
