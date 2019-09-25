# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :deny_non_bva_admins, only: [:represented_organizations]

  def index
    case params[:role]
    when Constants::USER_ROLE_TYPES["judge"]
      return render json: { judges: Judge.list_all }
    when Constants::USER_ROLE_TYPES["attorney"]
      return render json: { attorneys: json_attorneys(Judge.new(judge).attorneys) } if params[:judge_id]

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

  def judge
    @judge ||= User.find_by(id: params[:judge_id])
  end

  private

  def json_users(users)
    ::WorkQueue::UserSerializer.new(users, is_collection: true)
  end

  def json_attorneys(users)
    AttorneySerializer.new(users)
  end
end
