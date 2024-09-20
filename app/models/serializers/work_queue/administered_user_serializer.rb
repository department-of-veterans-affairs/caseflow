# frozen_string_literal: true

class WorkQueue::AdministeredUserSerializer < WorkQueue::UserSerializer
  include FastJsonapi::ObjectSerializer

  attribute :admin do |object, params|
    params[:organization].user_is_admin?(object)
  end
  attribute :dvc do |object, params|
    if params[:organization].type == DvcTeam.name
      params[:organization].dvc&.eql?(object)
    end
  end
  attribute :conference_provider
  attribute :user_permission do |object, params|
    object&.organization_permissions(params[:organization])
  end
  attribute :user_admin_permission do |object, params|
    object&.organization_admin_permissions(params[:organization])
  end
  attribute :description do |object, params|
    object&.organization_admin_permissions(params[:organization])
  end
end
