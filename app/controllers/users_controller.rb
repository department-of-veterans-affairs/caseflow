# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :deny_non_bva_admins, only: [:represented_organizations, :update, :search_by_css_id]

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

  def search_by_css_id
    user = User.find_by_css_id(css_id)

    fail ActiveRecord::RecordNotFound unless user

    render json: { user: user }
  end

  def update
    if params.key?(:status)
      user_to_modify.update_status!(params[:status])
    end

    render json: { user: user_to_modify }, status: :ok
  end

  def represented_organizations
    render json: { represented_organizations: User.find(params[:id]).vsos_user_represents }
  end

  def judge
    @judge ||= User.find_by(id: params[:judge_id])
  end

  private

  def css_id
    unless params[:css_id]
      fail(
        Caseflow::Error::InvalidParameter,
        parameter: "css_id",
        message: "Must provide a css id"
      )
    end

    params[:css_id]
  end

  def user_to_modify
    @user_to_modify ||= User.find(params.require(:id))
  end

  def json_users(users)
    ::WorkQueue::UserSerializer.new(users, is_collection: true)
  end
end
