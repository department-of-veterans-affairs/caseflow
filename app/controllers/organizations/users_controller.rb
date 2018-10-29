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
          organization_users: json_users(organization_users),
          remaining_users: json_users(remaining_users)
        }
      end
    end
  end

  def create
    OrganizationsUser.add_user_to_organization(user_to_modify, organization)

    render json: { users: json_users([user_to_modify]) }, status: 200
  end

  def destroy
    OrganizationsUser.remove_user_from_organization(user_to_modify, organization)

    render json: { users: json_users([user_to_modify]) }, status: 200
  end

  def verify_organization_access
    return if current_user.admin?

    super
  end

  def verify_role_access
    return if current_user.admin?

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
    ActiveModelSerializers::SerializableResource.new(
      users,
      each_serializer: ::WorkQueue::UserSerializer
    ).as_json
  end
end
