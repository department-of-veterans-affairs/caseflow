class TeamManagementController < ApplicationController
  before_action :deny_non_global_admins

  def index
    respond_to do |format|
      format.html { render template: "queue/index" }
      format.json do
        render json: {
          judge_teams: JudgeTeam.all.map { |jt| serialize_org(jt) },
          vsos: Vso.all.map { |vso| serialize_org(vso) },
          other_orgs: Organization.all.reject { |o| o.is_a?(JudgeTeam) || o.is_a?(Vso) }.map { |o| serialize_org(o) }
        }
      end
    end
  end

  def deny_non_global_admins
    redirect_to "/unauthorized" if current_user&.global_admin?
  end

  private

  def serialize_org(org)
    {
      id: org.id,
      name: org.name,
      participant_id: org.participant_id,
      type: org.type,
      url: org.url
    }
  end
end
