# frozen_string_literal: true

class WorkQueue::AdministeredUserSerializer < WorkQueue::UserSerializer
  include FastJsonapi::ObjectSerializer

  attribute :admin do |object, params|
    params[:organization].user_is_admin?(object)
  end
  attribute :judge do |object, params|
    if params[:organization].type == JudgeTeam.name
      params[:organization].judge&.eql?(object)
    end
  end
  attribute :attorney do |object, params|
    if params[:organization].type == JudgeTeam.name
      params[:organization].attorneys&.include?(object)
    end
  end
end
