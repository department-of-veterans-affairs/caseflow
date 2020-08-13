# frozen_string_literal: true

class DvcTeam < Organization
  
  class << self
    def for_dvc(user)
      user.administered_teams.detect { |team| team.is_a?(DvcTeam) && team.dvc.eql?(user) }
    end 

    def create_for_dvc(user) 
      fail(Caseflow::Error::DuplicateDvcTeam, user_id: user.id) if DvcTeam.for_dvc(user)

      create!(name: user.css_id, url: user.css_id.downcase).tap do |org|

        OrganizationsUser.make_user_admin(user, org)
      end
    end
  end

  def dvc
    admins.first 
  end

  def judges
    non_admins 
  end

  def can_receive_task?(_task)
    false
  end

  def selectable_in_queue?
    false
  end
end