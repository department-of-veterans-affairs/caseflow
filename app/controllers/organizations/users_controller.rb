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
          isVhaOrg: vha_organization?
        }
      end
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

    update_user_meeting_type
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

  def update_user_meeting_type
    byebug
    if params[:user]
      OrganizationsUser.update_user_conference_type(user_to_modify, organization)
    end
    byebug
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
