class TeamManagementController < ApplicationController
  before_action :deny_non_bva_admins

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
    org = Organization.find(params[:id])
    org.update!(update_params)

    render json: { org: serialize_org(org) }, status: :ok
  end

  # TODO: Log these creation operations
  def create_judge_team
    user = User.find(params[:user_id])
    org = JudgeTeam.create_for_judge(user)

    # TODO: Make sure user does not already have a judge team.

    render json: { org: serialize_org(org) }, status: :ok
  end

  # TODO: Log these creation operations
  def create_national_vso
    org = Vso.create!(update_params)

    render json: { org: serialize_org(org) }, status: :ok
  end

  def deny_non_bva_admins
    redirect_to "/unauthorized" unless Bva.singleton.user_has_access?(current_user)
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
      url: org.url,
      user_admin_path: org.user_admin_path
    }
  end
end
