# frozen_string_literal: true

class Organizations::UsersController < OrganizationsController
  def index
    @permissions = organization.organization_permissions.select(
      :permission, :description, :enabled, :parent_permission_id, :default_for_admin, :id
    )
    org_users = OrganizationsUser.where(organization_id: organization.id)
    users_with_permissions = {}
    org_users.each do |org_user|
      user = org_user.user
      org_user_permissions = OrganizationUserPermission.includes(
        :organization_permission, :organizations_user
      )
        .where(organizations_user_id: org_user.id).pluck(:permission, :permitted, :user_id)
      users_with_permissions[user[:id]] = org_user_permissions
    end

    # binding.pry
    @user_permissions = users_with_permissions
    respond_to do |format|
      format.html { render template: "queue/index" }
      format.json do
        organization_users = organization.users
        render json: {
          organization_name: organization.name,
          judge_team: organization.type == JudgeTeam.name,
          dvc_team: organization.type == DvcTeam.name,
          organization_users: json_administered_users(organization_users),
          membership_requests: pending_membership_requests,
          isVhaOrg: vha_organization?
        }
      end
    end
  end

  def modify_user_permission
    user_id = params[:userId]
    permission_name = params[:permissionName].strip
    org_url = params[:organization_url]
    org_permission = OrganizationPermission.find_by(permission: permission_name)

    # might need this in the very soon future
    # organization_user_permission = OrganizationUserPermission.find_by(organizations_user_id: user_id, organization_permission_id: org_permission.id)

    target_user = OrganizationsUser.find_by(user_id: user_id)
    org = Organization.find_by(url: org_url)

    org_permission_checker = OrganizationUserPermissionChecker.new
    if org_permission_checker.can?(permission_name:org_permission.permission, organization:org, user:target_user.user)
      org_user_permission = OrganizationUserPermission.find_by(
        organization_permission: org_permission,
        organizations_user: target_user
      )
      org_user_permission.update!(permitted: false)
      render json: { checked: false }

    else
      org_user_permission = OrganizationUserPermission.find_or_create_by!(
        organization_permission: org_permission,
        organizations_user: target_user
      )
      org_user_permission.permitted = true
      org_user_permission.save
      render json: { checked: true }
    end
  end

  def create
    organization.add_user(user_to_modify, current_user)

    render json: { users: json_administered_users([user_to_modify]) }, status: :ok
  end

  def update
    no_cache

    if params.key?(:admin)
      adjust_admin_rights
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

  def adjust_admin_rights
    if params[:admin] == true
      OrganizationsUser.make_user_admin(user_to_modify, organization)
    else
      OrganizationsUser.remove_admin_rights_from_user(user_to_modify, organization)
    end
  end

  def organization_url
    params[:organization_url]
  end

  def pending_membership_requests
    # Serialize the Membership Requests and extract the attributes
    if vha_organization?
      MembershipRequestSerializer.new(organization.membership_requests.includes(:requestor).assigned.order(:created_at),
                                      is_collection: true)
        .serializable_hash[:data]
        .map { |hash| hash[:attributes] }
    else
      []
    end
  end

  def vha_organization?
    vha_predocket_org_types = [::VhaCaregiverSupport, ::VhaCamo, ::VhaProgramOffice]
    # Check if the org is any of the types above or has the url vha for the general VHA BusinessLine object
    organization.url == "vha" || vha_predocket_org_types.any? { |org_type| organization.is_a?(org_type) }
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
