# frozen_string_literal: true

class UsersController < ApplicationController
  include CssIdConcern

  before_action :deny_non_bva_admins, only: [:represented_organizations, :update]

  def index
    return filter_by_role if params[:role]
    return filter_by_css_id_or_name if css_id

    render json: {}, status: :ok
  end

  def search
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
    return nil unless params[:css_id]

    return to_valid_css_id(params[:css_id]) if invalid_css_id?(params[:css_id])

    params[:css_id]
  end

  def filter_by_role
    finder = UserFinder.new(role: params[:role])
    users = finder.users

    case params[:role]
    when Constants::USER_ROLE_TYPES["judge"]
      render json: { judges: users }
    when Constants::USER_ROLE_TYPES["attorney"]
      return render json: { attorneys: json_attorneys(Judge.new(judge).attorneys) } if params[:judge_id]

      render json: { attorneys: users }
    when Constants::USER_ROLE_TYPES["hearing_coordinator"]
      render json: { coordinators: users }
    when "non_judges"
      render json: { non_judges: json_users(users) }
    end
  end

  def filter_by_css_id_or_name
    # the param name is css_id for convenience but we are more generous in what we search.
    finder = UserFinder.new(css_id: css_id, name: css_id)
    users = finder.users || []
    if params[:exclude_org]
      org = Organization.find_by_name_or_url(params[:exclude_org])
      users -= org.users
    end
    render json: { users: json_users(users) }
  end

  def user
    unless css_id || params[:id]
      fail(
        Caseflow::Error::InvalidParameter,
        parameter: "css_id or id",
        message: "Must provide a css id or user id"
      )
    end

    @user ||= params[:id] ? User.find(params[:id]) : User.find_by_css_id(css_id)
  end

  def user_to_modify
    @user_to_modify ||= User.find(params.require(:id))
  end

  def json_users(users)
    return [] if users.blank?

    ::WorkQueue::UserSerializer.new(users, is_collection: true)
  end

  def json_attorneys(users)
    AttorneySerializer.new(users)
  end
end
