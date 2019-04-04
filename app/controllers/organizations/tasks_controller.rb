# frozen_string_literal: true

class Organizations::TasksController < OrganizationsController
  before_action :verify_organization_access, only: [:index]
  before_action :verify_role_access, only: [:index]

  def index
    tasks = GenericQueue.new(user: organization).tasks

    render json: {
      organization_name: organization.name,
      tasks: json_tasks(tasks),
      id: organization.id,
      is_vso: organization.is_a?(::Vso)
    }
  end

  private

  def organization_url
    params[:organization_url]
  end

  def json_tasks(tasks)
    ActiveModelSerializers::SerializableResource.new(
      AppealRepository.eager_load_legacy_appeals_for_tasks(tasks),
      user: current_user,
      exclude_extra_fields: organization.is_a?(::Vso),
      exclude_hearing_locations: organization.is_a?(::Vso)
    ).as_json
  end
end
