# frozen_string_literal: true

class TeamManagementController < ApplicationController
  before_action :verify_access
  before_action :fail_on_duplicate_participant_id, only: :create

  def index
    respond_to do |format|
      format.html { render template: "queue/index" }
      format.json do
        render json: current_user.can_view_team_management? ? all_teams : judge_teams
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
    fail_on_duplicate_participant_id

    org = PrivateBar.create!(update_params)

    Rails.logger.info("Creating PrivateBar with parameters: #{update_params.inspect}")

    render json: { org: serialize_org(org) }, status: :ok
  end

  def create_national_vso
    fail_on_duplicate_participant_id

    org = Vso.create!(update_params)

    Rails.logger.info("Creating Vso with parameters: #{update_params.inspect}")

    render json: { org: serialize_org(org) }, status: :ok
  end

  def create_field_vso
    fail_on_duplicate_participant_id

    org = FieldVso.create!(update_params)

    Rails.logger.info("Creating FieldVso with parameters: #{update_params.inspect}")

    render json: { org: serialize_org(org) }, status: :ok
  end

  private

  def fail_on_duplicate_participant_id
    existing_org = Organization.find_by_participant_id(update_params[:participant_id])
    if existing_org
      fail(Caseflow::Error::DuplicateParticipantIdOrganization,
           participant_id: update_params[:participant_id],
           organization: existing_org)
    end
  end

  def update_params
    params.require(:organization).permit(
      :name, :participant_id, :url, :accepts_priority_pushed_cases, :ama_only_push, :ama_only_request,
      :exclude_appeals_from_affinity
    )
  end

  def judge_teams
    {
      judge_teams: JudgeTeam.order(:name).map { |jt| serialize_org(jt) }
    }
  end

  def all_teams
    judge_teams.merge(
      dvc_teams: DvcTeam.order(:name).map { |dt| serialize_org(dt) },
      private_bars: PrivateBar.order(:name).map { |private_bar| serialize_org(private_bar) },
      vsos: Vso.order(:name).map { |vso| serialize_org(vso) },
      vha_program_offices: VhaProgramOffice.order(:name).map { |vpo| serialize_org(vpo) },
      vha_regional_offices: VhaRegionalOffice.order(:name).map { |vro| serialize_org(vro) },
      education_rpos: EducationRpo.order(:name).map { |erpo| serialize_org(erpo) },
      other_orgs: other_orgs.map { |org| serialize_org(org) }
    )
  end

  def other_orgs
    rejected_orgs = [
      JudgeTeam,
      DvcTeam,
      Representative,
      VhaProgramOffice,
      VhaRegionalOffice,
      EducationRpo
    ]
    Organization.order(:name).reject do |org|
      rejected_orgs.any? { |excluded_org| org.is_a?(excluded_org) }
    end
  end

  def serialize_org(org)
    org.serialize.merge(
      current_user_can_toggle_priority_pushed_cases: current_user.can_view_judge_team_management?,
      user_admin_path: current_user.can_view_team_management? ? org.user_admin_path : nil
    )
  end

  def verify_access
    unless current_user.can_view_team_management? || current_user.can_view_judge_team_management?
      redirect_to "/unauthorized"
    end
  end
end
