# frozen_string_literal: true

class Organizations::UsersController < OrganizationsController
  def index
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
          isVhaOrg: vha_organization?,
          organization_permissions: organization.organization_permissions.select(
            :permission, :description, :enabled, :parent_permission_id, :default_for_admin, :id
          ),
          organization_user_permissions: user_permissions
        }
      end
    end
  end

  def modify_user_permission
    user_id, permission_name = user_permission_params

    org_permission = organization.organization_permissions.find_by(permission: permission_name)
    target_user = organization.organizations_users.find_by(user_id: user_id)

    if org_user_permission_checker.can?(
      permission_name: org_permission.permission,
      organization: organization,
      user: target_user.user
    )
      disable_permission(user_id: user_id, org_permission: org_permission, target_user: target_user)
      render json: { checked: false }

    else
      enable_permission(user_id: user_id, org_permission: org_permission, target_user: target_user)
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

    update_user_conference_provider
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

  def user_permissions
    organization.organizations_users.sort_by(&:user_id).as_json(
      only: [:user_id],
      include: [
        organization_user_permissions: { include: [organization_permission: { only: [:permission, :permitted] }] }
      ]
    )
  end

  def disable_permission(user_id:, org_permission:, target_user:)
    organization.organizations_users
      .find_by(user_id: user_id).organization_user_permissions
      .find_by(
        organization_permission: org_permission,
        organizations_user: target_user
      )
      .update(permitted: false)
  end

  def enable_permission(user_id:, org_permission:, target_user:)
    organization.organizations_users.find_by(user_id: user_id)
      .organization_user_permissions
      .find_or_create_by!(
        organization_permission: org_permission,
        organizations_user: target_user
      ).update!(permitted: true)
  end

  def org_user_permission_checker
    @org_user_permission_checker ||= OrganizationUserPermissionChecker.new
  end

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

  def update_user_conference_provider
    new_conference_provider = params.dig(:attributes, :conference_provider)

    if organization["url"] == HearingsManagement.singleton.url && new_conference_provider
      OrganizationsUser.update_user_conference_provider(user_to_modify, new_conference_provider)
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

  def user_permission_params
    params.permit(:userId, :permissionName)
    user_id = params[:userId]
    permission_name = params[:permissionName].strip
    [user_id, permission_name]
  end
end
