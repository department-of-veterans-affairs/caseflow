# frozen_string_literal: true

class TeamManagementController < ApplicationController
  before_action :deny_non_bva_admins

  def index
    respond_to do |format|
      format.html { render template: "queue/index" }
      format.json do
        render json: {
          judge_teams: JudgeTeam.all.order(:id).map { |jt| serialize_org(jt) },
          private_bars: PrivateBar.all.order(:id).map { |private_bar| serialize_org(private_bar) },
          vsos: Vso.all.order(:id).map { |vso| serialize_org(vso) },
          other_orgs: other_orgs.map { |org| serialize_org(org) }
        }
      end
    end
  end

  def update
    org = Organization.find(params[:id])

    Rails.logger.info("Updating existing record: #{org.inspect} with parameters: #{update_params.inspect}")

    org.update!(update_params)

    render json: { org: serialize_org(org) }, status: :ok
  end

  def create_judge_team
    user = User.find(params[:user_id])

    fail(Caseflow::Error::DuplicateJudgeTeam, user_id: user.id) if JudgeTeam.for_judge(user)

    Rails.logger.info("Creating JudgeTeam for user: #{user.inspect}")

    org = JudgeTeam.create_for_judge(user)

    render json: { org: serialize_org(org) }, status: :ok
  end

  def create_private_bar
    org = PrivateBar.create!(update_params)

    Rails.logger.info("Creating PrivateBar with parameters: #{update_params.inspect}")

    render json: { org: serialize_org(org) }, status: :ok
  end

  def create_national_vso
    org = Vso.create!(update_params)

    Rails.logger.info("Creating Vso with parameters: #{update_params.inspect}")

    render json: { org: serialize_org(org) }, status: :ok
  end

  def create_field_vso
    org = FieldVso.create!(update_params)

    Rails.logger.info("Creating FieldVso with parameters: #{update_params.inspect}")

    render json: { org: serialize_org(org) }, status: :ok
  end

  private

  def update_params
    params.require(:organization).permit(:name, :participant_id, :url)
  end

  def other_orgs
    Organization.all.order(:id).reject { |org| org.is_a?(JudgeTeam) || org.is_a?(Representative) }
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
