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
          membership_requests: membership_requests,
          isVhaOrg: vha_organization?
        }
      end
    end
  end

  def create
    organization.add_user(user_to_modify)

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

  # TODO: Don't use this method if they aren't a vha_organization for now since it's a waste of a database call
  def membership_requests
    # TODO: Use the serializer from Appeals-13115 and update it to include these fields
    MembershipRequest.includes(:requestor, :organization).where(organization: organization)
      .assigned
      .map do |membership_request|
        {
          id: membership_request.id,
          name: "#{membership_request.requestor.full_name} (#{membership_request.requestor.css_id})",
          requestedDate: membership_request.created_at,
          note: membership_request.note
        }
      end
  end

  def vha_organization?
    # TODO: This might cause an error if the constants are somehow not defined? Investigate if that is possible
    # Is it because the organization is an active model class and these orgs are just regular classes?
    # But they inherit from org so they should be subtyped correctly and it works in irb?
    # This apparently happens in develeopment environment but I don't know why.
    # Hardcoding strings to avoid for now
    # vha_org_types = [VhaCaregiverSupport, VhaCamo, VhaProgramOffice, VhaRegionalOffice]
    # vha_org = vha_org_types.any? { |org_type| organization.is_a?(org_type) } || organization.url == "vha"

    vha_program_office_names = [
      "Community Care - Payment Operations Management",
      "Community Care - Veteran and Family Members Program",
      "Member Services - Health Eligibility Center",
      "Member Services - Beneficiary Travel",
      "Prosthetics"
    ]

    # All VHA Organization names. This is not as nice as the contants but that errors for now.
    # TODO: Verify that it isn't just my development environment because this is nicer
    all_vha_org_names = [
      "Veterans Health Administration",
      "VHA Caregiver Support Program",
      "VHA CAMO",
      vha_program_office_names,
    ].flatten

    # vha_org_types.any? { |org_type| organization.is_a?(org_type) }
    all_vha_org_names.any? { |vha_org_name| organization.name == vha_org_name }
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
