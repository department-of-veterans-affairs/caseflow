# frozen_string_literal: true

class UsersController < ApplicationController
  include CssIdConcern

  before_action :deny_non_bva_admins, only: [:represented_organizations, :update]

  def index
    return filter_by_role if params[:role]
    return filter_by_css_id_or_name if css_id
    return filter_by_organization if params[:organization]

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
    render json: { represented_organizations: User.find(id).vsos_user_represents }
  end

  def judge
    @judge ||= User.find_by(id: params[:judge_id])
  end

  private

  def css_id
    @css_id ||= valid_css_id_or_nil
  end

  def valid_css_id_or_nil
    return nil unless params[:css_id].presence

    return normalize_css_id(params[:css_id]) if non_normalized_css_id?(params[:css_id])

    params[:css_id]
  end

  def filter_by_role # rubocop:disable Metrics/CyclomaticComplexity
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
    when "non_dvcs"
      render json: { non_dvcs: json_users(users) }
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

  def filter_by_organization
    finder = UserFinder.new(organization: params[:organization])
    users = finder.users || []

    render json: { users: json_users(users) }
  end

  # Depending on the route and the requested resource, the requested user's id could be sent as :id or :user_id
  # ex from rails routes: user GET /users/:id       or      user_task_pages GET /users/:user_id/task_pages
  def id
    @id ||= params[:id] || params[:user_id]
  end

  def user
    unless css_id || id
      fail(
        Caseflow::Error::InvalidParameter,
        parameter: "css_id or id",
        message: "Must provide a css id or user id"
      )
    end

    @user ||= id ? User.find(id) : User.find_by_css_id(css_id)
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
