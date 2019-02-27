class TeamManagementController < ApplicationController
  before_action :deny_non_global_admins

  def index
    respond_to do |format|
      format.html { render template: "queue/index" }
      format.json do
        render json: {
          judge_teams: JudgeTeam.all.order(:id).map { |jt| serialize_org(jt) },
          vsos: Vso.all.order(:id).map { |vso| serialize_org(vso) },
          other_orgs: Organization.all.order(:id).reject { |o| o.is_a?(JudgeTeam) || o.is_a?(Vso) }.map do |o|
            serialize_org(o)
          end
        }
      end
    end
  end

  def update
    # TODO: Add validation here.
    # TODO: Log every update request.
    # TODO: Make sure url stays lower-case
    org = Organization.find(params[:id])
    org.update!(
      name: update_params[:name],
      participant_id: update_params[:participant_id],
      url: update_params[:url]
    )

    render json: { org: serialize_org(org) }, status: :ok
  end

  def create_judge_team
    user = User.find(params[:user_id])
    org = JudgeTeam.create_for_judge(user)

    render json: { org: serialize_org(org) }, status: :ok
  end

  def deny_non_global_admins
    redirect_to "/unauthorized" if current_user&.global_admin?
  end

  private

  def update_params
    params.require(:organization).permit(:name, :participant_id, :url)
  end

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
