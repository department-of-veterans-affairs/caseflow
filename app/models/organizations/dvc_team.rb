# frozen_string_literal: true

class DvcTeam < Organization
  class << self
    def for_dvc(user)
      DvcTeam.find { |team| team.dvc.eql?(user) }
    end

    def create_for_dvc(user)
      fail(Caseflow::Error::DuplicateDvcTeam, user_id: user.id) if DvcTeam.for_dvc(user)

      create!(name: user.css_id, url: "#{user.css_id.downcase}_dvc_team").tap do |org|
        OrganizationsUser.make_user_admin(user, org)
      end
    end
  end

  def dvc
    # Currently we only allow one admin per DVC team
    admins.first
  end

  alias admin dvc

  def judges
    non_admins
  end

  def can_receive_task?(_task)
    false
  end

  def selectable_in_queue?
    false
  end

  def serialize
    super.merge(name: dvc&.full_name&.titleize)
  end
end
