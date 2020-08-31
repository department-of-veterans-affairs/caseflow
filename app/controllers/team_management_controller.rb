# frozen_string_literal: true

class TeamManagementController < ApplicationController
  before_action :deny_non_bva_admins

  def index
    respond_to do |format|
      format.html { render template: "queue/index" }
      format.json do
        render json: {
          judge_teams: JudgeTeam.order(:name).map { |jt| serialize_org(jt) },
          dvc_teams: DvcTeam.order(:name).map { |dt| serialize_org(dt) },
          private_bars: PrivateBar.order(:name).map { |private_bar| serialize_org(private_bar) },
          vsos: Vso.order(:name).map { |vso| serialize_org(vso) },
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

  def create_dvc_team
    user = User.find(params[:user_id])

    fail(Caseflow::Error::DuplicateDvcTeam, user_id: user.id) if DvcTeam.for_dvc(user)

    Rails.logger.info("Creating DvcTeam for user: #{user.inspect}")

    org = DvcTeam.create_for_dvc(user)

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
    Organization.order(:name).reject { |org| org.is_a?(JudgeTeam) || org.is_a?(DvcTeam) || org.is_a?(Representative) }
  end

  def serialize_org(org)
    org.serialize
  end
end
