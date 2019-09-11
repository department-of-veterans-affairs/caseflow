# frozen_string_literal: true

class UsersController < ApplicationController
  include BgsService

  before_action :deny_non_bva_admins, only: [:represented_organizations, :represented_organizations_by_css_id]

  def index
    case params[:role]
    when Constants::USER_ROLE_TYPES["judge"]
      return render json: { judges: Judge.list_all }
    when Constants::USER_ROLE_TYPES["attorney"]
      return render json: { attorneys: Judge.new(judge).attorneys } if params[:judge_id]

      return render json: { attorneys: Attorney.list_all }
    when Constants::USER_ROLE_TYPES["hearing_coordinator"]
      return render json: { coordinators: User.list_hearing_coordinators }
    when "non_judges"
      return render json: {
        non_judges: json_users(User.where.not(id: JudgeTeam.all.map(&:judge).reject(&:nil?).map(&:id)))
      }
    end
    render json: {}
  end

  def represented_organizations
    render json: { represented_organizations: User.find(params[:id]).vsos_user_represents }
  end

  def represented_organizations_by_css_id
    css_id = params[:css_id]
    station_id = params[:station_id]

    # TODO: Return an error if neither parameter are present

    participant_id = bgs.get_participant_id_for_css_id_and_station_id(css_id, station_id)
    vsos_user_represents = bgs.fetch_poas_by_participant_id(participant_id)

    render json: { represented_organizations: vsos_user_represents }
  end

  def judge
    @judge ||= User.find_by(id: params[:judge_id])
  end

  private

  def json_users(users)
    ::WorkQueue::UserSerializer.new(users, is_collection: true)
  end
end
