# frozen_string_literal: true

class Organizations::UsersController < OrganizationsController
  def index
    respond_to do |format|
      format.html { render template: "queue/index" }
      format.json do
        organization_users = organization.users
        remaining_users = User.where.not(id: organization_users.pluck(:id))

        remaining_users = remaining_users.select { |user| user.roles.include?(organization.role) } if organization.role

        render json: {
          organization_name: organization.name,
          organization_users: json_administered_users(organization_users),
          remaining_users: json_users(remaining_users)
        }
      end
    end
  end

  def create
    OrganizationsUser.add_user_to_organization(user_to_modify, organization)

    render json: { users: json_administered_users([user_to_modify]) }, status: :ok
  end

  def update
    no_cache

    if params.key?(:admin)
      if params[:admin] == true
        OrganizationsUser.make_user_admin(user_to_modify, organization)
      else
        OrganizationsUser.remove_admin_rights_from_user(user_to_modify, organization)
      end
    end

    render json: { users: json_administered_users([user_to_modify]) }, status: :ok
  end

  def destroy
    OrganizationsUser.remove_user_from_organization(user_to_modify, organization)

    render json: { users: json_users([user_to_modify]) }, status: :ok
  end

  def verify_organization_access
    return if current_user.administer_org_users?

    redirect_to "/unauthorized" unless current_user.administered_teams.include?(organization)
  end

  def verify_role_access
    return if current_user.administer_org_users?

    super
  end

  private

  def user_to_modify
    @user_to_modify ||= User.find(params.require(:id))
  end

  def organization_url
    params[:organization_url]
  end

  def json_users(users)
    ::WorkQueue::UserSerializer.new(users, is_collection: true)
  end

  def json_administered_users(users)
    ::WorkQueue::AdministeredUserSerializer.new(
      users,
      is_collection: true,
      params: { organization: organization }
    )
  end
end
