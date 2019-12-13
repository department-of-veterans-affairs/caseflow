# frozen_string_literal: true

class WorkQueue::AdministeredUserSerializer < WorkQueue::UserSerializer
  include FastJsonapi::ObjectSerializer

  attribute :admin do |object, params|
    params[:organization].user_is_admin?(object)
  end
  attribute :is_judge do |object, params|
    params[:organization].judge.eql?(object)
  end
  attribute :is_attorney do |object, params|
    params[:organization].attorneys.include?(object)
  end
end
