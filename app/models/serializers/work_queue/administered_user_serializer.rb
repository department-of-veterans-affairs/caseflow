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
end
